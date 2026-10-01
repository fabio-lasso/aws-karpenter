# Plantillas de despliegue Karpenter (buenas prácticas)

Plantillas de NodePools y NodeClasses de Karpenter / EKS Auto Mode que aplican la estrategia:

- **Spot amplio** (prioritario) + **On-Demand justo** (fallback).
- **Consolidación por entorno**: `WhenEmpty` en previos, `WhenEmptyOrUnderutilized` en producción.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| [`nodeclasses.yaml`](nodeclasses.yaml) | NodeClasses `preprod` y `prod` (red, rol IAM, tags, storage). |
| [`nodepools-preprod.yaml`](nodepools-preprod.yaml) | NodePools de entornos previos (dev/staging/qa). |
| [`nodepools-prod.yaml`](nodepools-prod.yaml) | NodePools de producción. |
| [`nodepool-gpu.yaml`](nodepool-gpu.yaml) | NodePool + NodeClass + workload GPU dedicado (con taint). |
| [`ejemplo-workload.yaml`](ejemplo-workload.yaml) | Deployment + PDB de ejemplo que consume las pools. |

> Para el detalle campo por campo de cada elemento, consulta la [Guía de referencia](../docs/guia-referencia/README.md).

---

## Estrategia: Spot amplio, On-Demand justo

Karpenter usa el campo **`weight`** del NodePool para decidir el orden de preferencia cuando varios NodePools pueden satisfacer un pod. Mayor `weight` = se intenta primero.

```yaml
# Spot: se intenta PRIMERO
spec:
  weight: 100
  template:
    spec:
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot"]
---
# On-Demand: FALLBACK
spec:
  weight: 10
  template:
    spec:
      requirements:
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["on-demand"]
```

### Por qué Spot "amplio"

Las buenas prácticas de EC2 Spot exigen **máxima flexibilidad** para que Karpenter tenga más *pools* de capacidad entre los que elegir (estrategia `price-capacity-optimized`). Esto reduce la frecuencia de interrupciones. Por eso el NodePool Spot abre:

- **Arquitecturas**: `amd64` + `arm64` (Graviton).
- **Familias**: `c`, `m`, `r`, `t`.
- **Tamaños**: todos menos los más pequeños (`NotIn [nano, micro, small, medium]`).
- **Zonas**: todas las disponibles (`topology.kubernetes.io/zone: Exists`).

> No restrinjas en exceso Spot. Cuantas más instancias seleccionables, mejor disponibilidad y menor costo. Además, la consolidación **Spot-a-Spot** solo actúa con ≥15 tipos de instancia seleccionables.

### Por qué On-Demand "justo"

On-Demand es el *fallback* y debe ser **predecible y acotado** para costo controlado:

- **Arquitectura**: solo `amd64`.
- **Familias**: `c`, `m`.
- **Tamaños**: lista cerrada (`In [xlarge, 2xlarge]` en previos; `+4xlarge` en prod).

Así, cuando no hay capacidad Spot, caes en instancias conocidas y dimensionables, evitando sorpresas de costo.

---

## Consolidación por entorno

| Entorno | `consolidationPolicy` | Motivo |
|---------|----------------------|--------|
| **Previos** (dev/staging/qa) | `WhenEmpty` | Conservador: solo elimina nodos **vacíos**. Menos disrupción mientras pruebas. |
| **Producción** | `WhenEmptyOrUnderutilized` | Optimiza costo activamente: también reemplaza nodos **subutilizados** por otros más pequeños/económicos. |

### Disruption budgets

- **Previos**: `30%` (más permisivo, no hay tráfico productivo).
- **Producción**:
  - `10%` general.
  - `1` nodo a la vez para `Underutilized` (reemplazos controlados).
  - Ventana `0` en horario pico (ejemplo `0 8 * * mon-fri` por `12h`) para no interrumpir en producción.

> Ajusta la zona horaria y el `cron`/`duration` a tu operación real.

---

## Despliegue

Las plantillas usan variables que debes resolver antes de aplicar:

- `$NODE_IAM_ROLE` — rol IAM del nodo.
- `$DISCOVERY_TAG` — valor del tag `karpenter.sh/discovery` (p. ej. el nombre del clúster).

### Opción A — exportar variables y sustituir con `envsubst`

```bash
export NODE_IAM_ROLE="arn:aws:iam::<account>:role/<node-role>"
export DISCOVERY_TAG="karpenter-workshop"

# Entornos previos
envsubst < templates/nodeclasses.yaml      | kubectl apply -f -
envsubst < templates/nodepools-preprod.yaml | kubectl apply -f -

# Producción
envsubst < templates/nodeclasses.yaml   | kubectl apply -f -
envsubst < templates/nodepools-prod.yaml | kubectl apply -f -
```

> Nota: `nodeclasses.yaml` define `preprod` y `prod`. Aplícalo una sola vez por clúster; cada NodePool referencia la NodeClass de su entorno.

### Opción B — aplicar directamente (si las variables ya están en el shell del workshop)

```bash
cat templates/nodepools-prod.yaml | kubectl apply -f -
```

### Verificar

```bash
kubectl get nodepools -L environment -L capacity
kubectl get nodeclasses
```

Visualiza la preferencia Spot → On-Demand en acción:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool,karpenter.sh/capacity-type
```

---

## Buenas prácticas aplicadas (resumen)

- ✅ **Spot amplio / On-Demand justo** mediante `weight` (100 vs 10).
- ✅ **No fijar `capacity-type` en los pods**: deja que el `weight` decida (ver [`ejemplo-workload.yaml`](ejemplo-workload.yaml)).
- ✅ **`requests = limits`** en memoria para evitar OOM al consolidar.
- ✅ **`consolidationPolicy` por entorno** (`WhenEmpty` vs `WhenEmptyOrUnderutilized`).
- ✅ **Disruption budgets** proporcionales al entorno + ventana de pico en prod.
- ✅ **`expireAfter` + `terminationGracePeriod`** para ciclo de vida máximo de nodos.
- ✅ **`topologySpreadConstraints` + PodDisruptionBudget** para resiliencia multi-AZ.
- ✅ **Diversidad de instancias y AZ** en Spot (`price-capacity-optimized`).
- ✅ **Tags de costo** por entorno en la NodeClass.

> Consulta la documentación del workshop en [`../docs/04-karpenter/`](../docs/04-karpenter/README.md) para el detalle conceptual de cada punto.
