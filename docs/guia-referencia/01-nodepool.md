# Guía de referencia · NodePool

El **NodePool** es el recurso de Karpenter que define *qué tipo de nodos* puede crear Karpenter y *cómo* se gestiona su ciclo de vida. Un clúster puede tener varios NodePools (además de los gestionados `general-purpose` y `system` de EKS Auto Mode).

`apiVersion: karpenter.sh/v1` · `kind: NodePool`

## Estructura general

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: <nombre>
  labels: { ... }
spec:
  weight: <entero>
  template:
    metadata:
      labels: { ... }
      annotations: { ... }
    spec:
      nodeClassRef: { ... }
      requirements: [ ... ]
      taints: [ ... ]
      startupTaints: [ ... ]
      expireAfter: <duración>
      terminationGracePeriod: <duración>
  limits: { cpu, memory }
  disruption:
    consolidationPolicy: <WhenEmpty | WhenEmptyOrUnderutilized>
    consolidateAfter: <duración>
    budgets: [ ... ]
```

---

## `metadata`

| Campo | Descripción |
|-------|-------------|
| `metadata.name` | Nombre único del NodePool en el clúster. Se usa como valor del label `karpenter.sh/nodepool` en los nodos que crea. |
| `metadata.labels` | Labels sobre el objeto NodePool (no sobre los nodos). Útiles para filtrar con `kubectl get nodepools -l ...`. |

---

## `spec.weight`

**Tipo:** entero (0–100). **Opcional** (por defecto `0`).

Define la **prioridad** del NodePool cuando varios NodePools pueden satisfacer un mismo pod. **Mayor peso = se intenta primero.**

```yaml
spec:
  weight: 100   # este NodePool se evalúa antes que uno con weight 10
```

> **Buena práctica (Spot amplio / On-Demand justo):** asigna `weight: 100` al NodePool Spot y `weight: 10` al On-Demand. Así Karpenter intenta Spot primero y cae a On-Demand solo si no hay capacidad Spot.

---

## `spec.template`

Es la **plantilla del nodo**: todo lo que define cómo serán los nodos creados por este NodePool.

### `spec.template.metadata.labels`

Labels que se aplican a **cada nodo** creado. Los pods pueden seleccionarlos con `nodeSelector`.

```yaml
template:
  metadata:
    labels:
      intent: apps          # label de negocio para dirigir workloads
      environment: prod
      team: payments
```

### `spec.template.metadata.annotations`

Anotaciones aplicadas a los nodos. La más relevante:

| Anotación | Efecto |
|-----------|--------|
| `karpenter.sh/do-not-disrupt: "true"` | Karpenter no interrumpirá (consolidación/drift/expiración) los nodos con esta anotación. Útil para nodos sensibles. |

### `spec.template.spec.nodeClassRef`

**Obligatorio.** Referencia a la **NodeClass** que define la infraestructura (subnets, security groups, rol IAM, storage).

```yaml
nodeClassRef:
  group: eks.amazonaws.com   # para EKS Auto Mode
  kind: NodeClass
  name: prod
```

> Varios NodePools pueden referenciar la misma NodeClass.

### `spec.template.spec.requirements`

**Lista de restricciones** que acotan qué instancias EC2 puede lanzar este NodePool. Cada entrada tiene `key`, `operator` y (según el operador) `values`.

```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot"]
  - key: eks.amazonaws.com/instance-generation
    operator: Gt
    values: ["2"]
```

**Operadores soportados:**

| Operador | Significado |
|----------|-------------|
| `In` | El valor del nodo debe estar en la lista. |
| `NotIn` | El valor del nodo NO debe estar en la lista. |
| `Exists` | La etiqueta debe existir (sin importar su valor). Útil para "todas las AZ". |
| `DoesNotExist` | La etiqueta no debe existir. |
| `Gt` | Mayor que (un solo valor numérico). Ej: generación `> 2`. |
| `Lt` | Menor que (un solo valor numérico). |

> El detalle de todas las *keys* (capacity-type, arch, instance-category, etc.) está en [03-requirements-labels.md](03-requirements-labels.md).

### `spec.template.spec.taints`

Taints aplicados a los nodos. Solo los pods con la **toleration** correspondiente podrán programarse ahí. Patrón típico para aislar NodePools dedicados (ej. `team1`, GPU).

```yaml
taints:
  - key: nvidia.com/gpu
    effect: NoSchedule        # NoSchedule | PreferNoSchedule | NoExecute
    # value: "true"           # opcional
```

### `spec.template.spec.startupTaints`

Taints aplicados **solo durante el arranque** del nodo (p. ej. mientras un DaemonSet de inicialización se instala). Se eliminan cuando el componente los retira. No requieren toleration permanente en los pods de aplicación.

### `spec.template.spec.expireAfter`

Tiempo máximo de vida de un nodo antes de ser reemplazado (refresco por seguridad/parches). Respeta PDBs, `terminationGracePeriodSeconds` y la anotación `do-not-disrupt`.

```yaml
expireAfter: 336h   # 14 días. Formatos: s, m, h. "Never" lo desactiva.
```

> Los nodos de EKS Auto Mode tienen una vida máxima de **21 días** independientemente de este valor.

### `spec.template.spec.terminationGracePeriod`

Tiempo máximo que un nodo puede estar en *draining* antes de ser **forzosamente** eliminado. Combinado con `expireAfter` fija un ciclo de vida máximo garantizado.

```yaml
terminationGracePeriod: 24h
```

> ⚠️ Durante este período, incluso pods con PDBs que bloquean el desalojo serán eliminados al vencer el plazo. Dimensiónalo según tus cargas.

---

## `spec.limits`

Límite **agregado** de recursos que este NodePool puede aprovisionar. Cuando se alcanza, Karpenter deja de crear nodos para ese NodePool. Es un control de gasto/escala.

```yaml
limits:
  cpu: "1000"       # 1000 vCPU totales
  memory: 1000Gi    # 1000 GiB totales
```

> También puedes limitar recursos extendidos, p. ej. `nvidia.com/gpu: "8"`.

---

## `spec.disruption`

Controla **cómo y cuándo** Karpenter interrumpe (termina/reemplaza) nodos.

### `consolidationPolicy`

| Valor | Comportamiento | Cuándo usarlo |
|-------|----------------|---------------|
| `WhenEmpty` | Solo elimina nodos **completamente vacíos** (sin pods de workload). Conservador. | Entornos previos, cargas batch, donde quieres mínima disrupción. |
| `WhenEmptyOrUnderutilized` | Además de los vacíos, **reemplaza nodos subutilizados** por otros más pequeños/económicos y redistribuye pods. | Producción con microservicios stateless, para optimizar costo activamente. |

```yaml
disruption:
  consolidationPolicy: WhenEmptyOrUnderutilized
```

> ⚠️ Con `WhenEmptyOrUnderutilized` se recomienda `requests = limits` para recursos distintos de CPU (evita OOM al empaquetar).

### `consolidateAfter`

Tiempo que Karpenter espera, tras un cambio (pod añadido/eliminado), antes de consolidar. Amortigua reacciones bruscas.

```yaml
consolidateAfter: 30s   # 0s = reacciona de inmediato; "Never" = nunca consolida
```

### `budgets` (Disruption Budgets)

Lista de presupuestos que **limitan cuántos nodos** se pueden interrumpir a la vez. Si hay varios, Karpenter aplica el **más restrictivo**. Un budget sin `reasons` aplica a **todas** las razones.

```yaml
budgets:
  - nodes: "10%"                      # regla general: máx 10% a la vez
  - nodes: "1"
    reasons: ["Underutilized"]        # subutilizados: de 1 en 1
  - nodes: "0"
    schedule: "0 8 * * mon-fri"       # ventana de bloqueo (cron)
    duration: 12h                     # dura 12h desde el inicio del cron
```

| Campo del budget | Descripción |
|------------------|-------------|
| `nodes` | Número absoluto (`"3"`) o porcentaje (`"20%"`) de nodos que pueden interrumpirse. `"0"` bloquea toda disrupción. |
| `reasons` | Lista de razones a las que aplica: `Empty`, `Underutilized`, `Drifted`. Si se omite, aplica a todas. |
| `schedule` | Expresión cron que indica **cuándo** aplica el budget. |
| `duration` | Cuánto dura la ventana desde que arranca el `schedule` (formato `h`/`m`). |

**Razones de disrupción:**

| Razón | Significado |
|-------|-------------|
| `Empty` | El nodo quedó vacío. |
| `Underutilized` | El nodo está subutilizado y puede eliminarse/reemplazarse. |
| `Drifted` | El nodo difiere de su estado deseado (p. ej. AMI desactualizada). |

> **Buena práctica producción:** `10%` general + `1` para `Underutilized` + ventana `0` en horario pico. Combínalo con **PodDisruptionBudgets** a nivel de aplicación.

---

## Ejemplo completo comentado

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: prod-spot
spec:
  weight: 100                               # Spot primero (fallback: On-Demand con weight menor)
  template:
    metadata:
      labels:
        intent: apps
        environment: prod
    spec:
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: prod
      expireAfter: 336h                      # refresco a los 14 días
      terminationGracePeriod: 24h
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]                   # solo Spot
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]         # amplio: incluye Graviton
        - key: eks.amazonaws.com/instance-category
          operator: In
          values: ["c", "m", "r", "t"]       # amplio: muchas familias
        - key: eks.amazonaws.com/instance-size
          operator: NotIn
          values: [nano, micro, small, medium]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["2"]
        - key: topology.kubernetes.io/zone
          operator: Exists                    # todas las AZ
  limits:
    cpu: "2000"
    memory: 2000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 2m
    budgets:
      - nodes: "10%"
      - nodes: "1"
        reasons: ["Underutilized"]
```

---

⬅️ [Índice de la guía](README.md) · ➡️ [NodeClass](02-nodeclass.md)
