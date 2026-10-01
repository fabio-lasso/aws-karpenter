# Guía de referencia · GPU y aceleradores

EKS Auto Mode y Karpenter pueden aprovisionar instancias con **GPU** (familias `g`, `p`) y otros aceleradores. El patrón recomendado es un **NodePool dedicado con taint** para que solo las cargas que piden GPU aterricen en esos nodos (caros).

## Estrategia

1. **NodePool dedicado** con `taint` (p. ej. `nvidia.com/gpu:NoSchedule`) para aislar los nodos GPU.
2. **Requirements** que acotan a familias GPU y, opcionalmente, al modelo de GPU.
3. **Workload** que pide `nvidia.com/gpu` en `resources` y **tolera** el taint.
4. **Consolidación conservadora** (GPU suele ser stateful/largo) y **límites** de GPU para controlar gasto.

> [!IMPORTANT]
> Las instancias GPU son costosas. Usa taints + límites + `do-not-disrupt` en jobs críticos para evitar sorpresas.

## Requirements típicos GPU

```yaml
requirements:
  - key: eks.amazonaws.com/instance-category
    operator: In
    values: ["g", "p"]                     # familias con GPU
  - key: eks.amazonaws.com/instance-gpu-manufacturer
    operator: In
    values: ["nvidia"]
  # Opcional: modelo de GPU concreto
  - key: eks.amazonaws.com/instance-gpu-name
    operator: In
    values: ["t4", "a10g", "l4"]
  # Opcional: nº mínimo de GPUs
  - key: eks.amazonaws.com/instance-gpu-count
    operator: Gt
    values: ["0"]
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand"]                  # GPU: suele preferirse On-Demand/reserved
```

## Labels de GPU disponibles

| Label | Ejemplo | Uso |
|-------|---------|-----|
| `eks.amazonaws.com/instance-gpu-name` | `t4` | Seleccionar modelo de GPU. |
| `eks.amazonaws.com/instance-gpu-manufacturer` | `nvidia` | Filtrar por fabricante. |
| `eks.amazonaws.com/instance-gpu-count` | `1` | Nº de GPUs por nodo. |
| `eks.amazonaws.com/instance-gpu-memory` | `16384` | Memoria de GPU (MiB). |

## Límites de GPU en el NodePool

```yaml
limits:
  cpu: "500"
  memory: 500Gi
  nvidia.com/gpu: "8"      # tope de GPUs que este NodePool puede aprovisionar
```

## Workload que pide GPU

```yaml
spec:
  nodeSelector:
    intent: gpu
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule          # tolera el taint del NodePool GPU
  containers:
    - name: cuda-app
      image: <tu-imagen-cuda>
      resources:
        requests:
          nvidia.com/gpu: "1"
        limits:
          nvidia.com/gpu: "1"     # para GPU: request = limit (recurso entero, no fraccionable)
```

> El *device plugin* de NVIDIA expone el recurso `nvidia.com/gpu`. En EKS Auto Mode, el soporte de GPU viene gestionado; revisa la documentación de [cargas aceleradas](https://docs.aws.amazon.com/eks/latest/userguide/auto-accelerated.html).

## Modos de aprovisionamiento (AI/ML)

EKS Auto Mode soporta dos modos para cómputo acelerado:

| Modo | Descripción |
|------|-------------|
| **Dynamic provisioning** | Aprovisiona y escala instancias aceleradas según los pods que se programan (comportamiento Karpenter habitual). |
| **Static provisioning** | Capacidad acelerada reservada por adelantado (Capacity Blocks / ODCR), seleccionada con `capacityReservationSelectorTerms` en la NodeClass. |

> EKS Auto Mode siempre aprovisiona primero la capacidad **reservada**, luego Spot u On-Demand.

---

## Plantilla lista para usar

Ver [`../../templates/nodepool-gpu.yaml`](../../templates/nodepool-gpu.yaml) para un NodePool + NodeClass + workload de ejemplo GPU completos y comentados.

---

⬅️ [Workload](04-workload.md) · 🏠 [Índice de la guía](README.md)
