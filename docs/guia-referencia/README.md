# Guía de referencia de configuración · Karpenter / EKS Auto Mode

Guía exhaustiva en español que documenta **campo por campo** cada elemento de configuración posible de Karpenter en EKS Auto Mode: el recurso `NodePool`, el recurso `NodeClass`, las *well-known labels* usadas en `requirements`, los campos del lado del *workload*, y el caso de GPU/aceleradores.

## Contenido

| # | Documento | Qué cubre |
|---|-----------|-----------|
| 1 | [NodePool](01-nodepool.md) | `weight`, `template`, `requirements`, `taints`, `expireAfter`, `terminationGracePeriod`, `limits`, `disruption` (consolidationPolicy, consolidateAfter, budgets). |
| 2 | [NodeClass](02-nodeclass.md) | `subnetSelectorTerms`, `securityGroupSelectorTerms`, `role`, `ephemeralStorage`, `tags`, `kmsKeyID`, red avanzada, `capacityReservationSelectorTerms`. |
| 3 | [Requirements y labels](03-requirements-labels.md) | Operadores y todas las *well-known labels* (estándar y `eks.amazonaws.com/`), opciones de compra de capacidad. |
| 4 | [Workload](04-workload.md) | `nodeSelector`, `affinity`, `tolerations`, `resources`, `topologySpreadConstraints`, `do-not-disrupt`, PodDisruptionBudget, `terminationGracePeriodSeconds`. |
| 5 | [GPU y aceleradores](05-gpu.md) | NodePool GPU dedicado, labels de GPU, límites, workload con `nvidia.com/gpu`, modos de aprovisionamiento AI/ML. |

## Cómo se relacionan los recursos

```
          ┌─────────────────────────────────────────────┐
  Pod ──▶ │ nodeSelector / affinity / tolerations        │
          │ resources.requests  (lo que Karpenter mira)  │
          └───────────────────────┬─────────────────────┘
                                   │ dispara aprovisionamiento
                                   ▼
          ┌─────────────────────────────────────────────┐
          │ NodePool  (karpenter.sh/v1)                  │
          │  - weight        -> prioridad (Spot/OnDemand)│
          │  - requirements  -> qué instancias EC2       │
          │  - taints        -> aislamiento              │
          │  - disruption    -> consolidación / budgets  │
          │  - limits        -> tope de recursos         │
          │  - nodeClassRef ─────────────┐               │
          └──────────────────────────────┼──────────────┘
                                          ▼
          ┌─────────────────────────────────────────────┐
          │ NodeClass  (eks.amazonaws.com/v1)            │
          │  - subnets / security groups / role IAM      │
          │  - ephemeralStorage / tags / kms / red       │
          └─────────────────────────────────────────────┘
```

## Plantillas relacionadas

Las plantillas listas para usar que aplican estas configuraciones están en [`../../templates/`](../../templates/README.md):

- `nodeclasses.yaml`, `nodepools-preprod.yaml`, `nodepools-prod.yaml`
- `nodepool-gpu.yaml`, `ejemplo-workload.yaml`

## Nota sobre `consolidationPolicy`

Este material usa las dos políticas vistas en el workshop:

- `WhenEmpty` — solo elimina nodos vacíos (conservador).
- `WhenEmptyOrUnderutilized` — también reemplaza nodos subutilizados (optimiza costo).

> La documentación oficial de AWS muestra en algún ejemplo el valor `Balanced`. Verifica la política soportada por la versión de EKS Auto Mode de tu clúster con `kubectl explain nodepool.spec.disruption.consolidationPolicy` antes de aplicar en producción.

---

🏠 [Volver a la documentación del workshop](../../README.md)
