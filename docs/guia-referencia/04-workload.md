# Guía de referencia · Workload (cómo consumir los NodePools)

Un NodePool define qué nodos *pueden* crearse, pero son los **pods** quienes disparan y dirigen el aprovisionamiento. Esta guía documenta los campos del lado del workload que influyen en Karpenter.

## `nodeSelector`

Forma más simple de **dirigir** un pod hacia nodos con ciertas labels. Debe coincidir **exactamente** (AND de todas las entradas).

```yaml
spec:
  nodeSelector:
    intent: apps                        # label del template del NodePool
    environment: prod
    kubernetes.io/arch: arm64           # fuerza Graviton
    karpenter.sh/capacity-type: spot    # fuerza Spot
    karpenter.sh/nodepool: team1        # fuerza un NodePool concreto
```

> **Buena práctica:** si NO fijas `karpenter.sh/capacity-type`, dejas que el `weight` de los NodePools decida (Spot primero, On-Demand fallback). Fíjalo solo cuando la carga lo exija.

## `affinity` / `nodeAffinity`

Alternativa más expresiva a `nodeSelector`: permite reglas `required` (obligatorias) y `preferred` (preferencias con peso), y operadores (`In`, `NotIn`, `Gt`, `Lt`, `Exists`).

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: eks.amazonaws.com/instance-category
                operator: In
                values: ["c", "m"]
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values: ["arm64"]       # prefiere Graviton, pero no obliga
```

## `tolerations`

Permiten que un pod se programe en nodos con **taints**. Obligatorio si el NodePool aplica taints (p. ej. NodePool dedicado o GPU).

```yaml
spec:
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
    # o con valor explícito:
    - key: team1
      operator: Equal
      value: "true"
      effect: NoSchedule
```

| Campo | Descripción |
|-------|-------------|
| `key` | La key del taint a tolerar. |
| `operator` | `Exists` (solo la key) o `Equal` (key + value). |
| `value` | Valor a igualar (solo con `Equal`). |
| `effect` | `NoSchedule`, `PreferNoSchedule`, `NoExecute`. Debe coincidir con el taint. |

> La relación es: el **NodePool** define el `taint` → el **pod** debe tener la `toleration`. Ver [01-nodepool.md](01-nodepool.md).

## `resources.requests` / `resources.limits`

Base de las decisiones de Karpenter. Karpenter aprovisiona nodos según los **requests** agregados de los pods pendientes. **No** considera los `limits` ni la utilización real.

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
    # recursos extendidos:
    # nvidia.com/gpu: "1"
  limits:
    memory: "512Mi"      # memoria: limit = request (recomendado)
    # nvidia.com/gpu: "1"
```

> [!IMPORTANT]
> Con `consolidationPolicy: WhenEmptyOrUnderutilized`, define **`requests = limits` en memoria** (y otros recursos no-CPU). La consolidación empaqueta pods usando solo los requests; si varios pods hacen *burst* de memoria por encima del request, puede ocurrir OOM.

## `topologySpreadConstraints`

Reparten los pods entre dominios (zonas, nodos) para resiliencia. Karpenter los respeta al aprovisionar.

```yaml
topologySpreadConstraints:
  - maxSkew: 1                                 # diferencia máx. de pods entre dominios
    topologyKey: topology.kubernetes.io/zone   # dominio: zona de disponibilidad
    whenUnsatisfiable: DoNotSchedule           # DoNotSchedule | ScheduleAnyway
    minDomains: 3                              # exige al menos 3 dominios (zonas)
    labelSelector:
      matchLabels:
        app: mi-app
```

| Campo | Descripción |
|-------|-------------|
| `maxSkew` | Diferencia máxima permitida de pods entre dominios. |
| `topologyKey` | Label que define el dominio (`.../zone`, `kubernetes.io/hostname`). |
| `whenUnsatisfiable` | `DoNotSchedule` (estricto, fuerza nuevos nodos/zonas) o `ScheduleAnyway` (preferencia). |
| `minDomains` | Número mínimo de dominios que deben existir. |

> Con `DoNotSchedule` + `minDomains: 3`, Karpenter crea nodos en al menos 3 zonas distintas aunque pudiera empaquetarlos en uno solo.

## `podAffinity` / `podAntiAffinity`

Programan pods **cerca** (`podAffinity`) o **lejos** (`podAntiAffinity`) de otros pods según sus labels. `podAntiAffinity` con `topologyKey: kubernetes.io/hostname` fuerza un pod por nodo.

## Anotación `karpenter.sh/do-not-disrupt`

En un **pod**, evita que Karpenter interrumpa el nodo donde corre (mientras el pod exista). Útil para jobs críticos que no deben moverse.

```yaml
metadata:
  annotations:
    karpenter.sh/do-not-disrupt: "true"
```

> También puede ir en el **NodePool** (`template.metadata.annotations`) para proteger todos sus nodos.

## PodDisruptionBudget (PDB)

Recurso independiente que limita cuántos pods de un conjunto pueden estar indisponibles a la vez durante disrupciones **voluntarias** (incluidas las de Karpenter).

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mi-app-pdb
spec:
  minAvailable: 50%          # o maxUnavailable: 1
  selector:
    matchLabels:
      app: mi-app
```

| Campo | Descripción |
|-------|-------------|
| `minAvailable` | Mínimo de pods que deben seguir disponibles (número o %). |
| `maxUnavailable` | Máximo de pods que pueden estar indisponibles (alternativa a `minAvailable`). |
| `selector` | Qué pods cubre el PDB. |

> **Combinación recomendada:** *Disruption Budgets* en el NodePool (plataforma) + **PDB** en la aplicación. Juntos dan control de disrupción voluntaria a ambos niveles.

## `terminationGracePeriodSeconds`

Tiempo que Kubernetes da al pod para apagarse tras recibir **SIGTERM** antes de enviar SIGKILL. Clave para manejar interrupciones Spot con elegancia.

```yaml
spec:
  terminationGracePeriodSeconds: 60
```

---

## Ejemplo completo comentado

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      nodeSelector:
        intent: apps
        environment: prod          # NO fija capacity-type: el weight decide (Spot->On-Demand)
      terminationGracePeriodSeconds: 60
      containers:
        - name: mi-app
          image: public.ecr.aws/nginx/nginx:latest
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              memory: "512Mi"       # limit = request (evita OOM al consolidar)
          ports:
            - containerPort: 80
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: mi-app
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mi-app-pdb
spec:
  minAvailable: 50%
  selector:
    matchLabels:
      app: mi-app
```

---

⬅️ [Requirements y labels](03-requirements-labels.md) · ➡️ [GPU / aceleradores](05-gpu.md)
