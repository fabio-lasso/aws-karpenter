# Infraestructura como código · Kustomize y Helm

Dos formas de desplegar los NodePools/NodeClasses de Karpenter de forma parametrizada por entorno, aplicando la estrategia **Spot amplio / On-Demand justo** y la consolidación por entorno (**WhenEmpty** en previos, **WhenEmptyOrUnderutilized** en producción).

> Las plantillas YAML "planas" equivalentes están en [`../templates/`](../templates/README.md). La explicación campo por campo está en la [guía de referencia](../docs/guia-referencia/README.md).

---

## Opción 1 · Kustomize

Estructura base + overlays:

```
kustomize/
├── base/
│   ├── kustomization.yaml
│   ├── nodeclass.yaml
│   ├── nodepool-spot.yaml        # amplio, weight 100
│   └── nodepool-on-demand.yaml   # justo, weight 10
└── overlays/
    ├── preprod/   # WhenEmpty, budgets 30%, prefijo preprod-
    ├── prod/      # WhenEmptyOrUnderutilized, budgets estrictos + ventana pico
    └── gpu/       # NodePool + NodeClass GPU dedicado (taint nvidia.com/gpu)
```

### Previsualizar

```bash
kubectl kustomize kustomize/overlays/preprod
kubectl kustomize kustomize/overlays/prod
kubectl kustomize kustomize/overlays/gpu
```

### Aplicar

```bash
kubectl apply -k kustomize/overlays/prod
# GPU (opcional, junto a prod):
kubectl apply -k kustomize/overlays/gpu
```

> Antes de aplicar, ajusta en cada overlay el `karpenter.sh/discovery` y el `role` (están como `mi-cluster-*` / `mi-cluster-eks-node-role`).

---

## Opción 2 · Helm

Chart en `helm/karpenter-nodepools/` con un `values.yaml` por defecto y values por entorno.

```
helm/karpenter-nodepools/
├── Chart.yaml
├── values.yaml            # defaults (preprod)
├── values-preprod.yaml
├── values-prod.yaml
├── values-gpu.yaml
└── templates/
    ├── _helpers.tpl
    ├── nodeclass.yaml
    └── nodepools.yaml      # itera sobre .Values.nodePools
```

### Previsualizar (render sin aplicar)

```bash
helm template preprod helm/karpenter-nodepools -f helm/karpenter-nodepools/values-preprod.yaml
helm template prod    helm/karpenter-nodepools -f helm/karpenter-nodepools/values-prod.yaml
helm template gpu     helm/karpenter-nodepools -f helm/karpenter-nodepools/values-gpu.yaml
```

### Instalar

```bash
helm upgrade --install knp-prod helm/karpenter-nodepools \
  -f helm/karpenter-nodepools/values-prod.yaml

# GPU como release aparte:
helm upgrade --install knp-gpu helm/karpenter-nodepools \
  -f helm/karpenter-nodepools/values-gpu.yaml
```

### Parámetros principales (`values.yaml`)

| Clave | Descripción |
|-------|-------------|
| `environment` | Prefijo y label de entorno. |
| `nodeClass.discoveryTag` | Valor del tag `karpenter.sh/discovery`. |
| `nodeClass.role` | Rol IAM del nodo. |
| `nodeClass.ephemeralStorage` | `size`, `iops`, `throughput`. |
| `nodePools[]` | Lista de NodePools a crear. |

Campos de cada `nodePools[]`:

| Campo | Descripción |
|-------|-------------|
| `name`, `weight`, `intent` | Nombre, prioridad y label `intent`. |
| `capacityType` | Lista: `["spot"]`, `["on-demand"]`, etc. |
| `arch` | `["amd64","arm64"]`. |
| `instanceCategory` | `["c","m","r","t"]`, `["g","p"]`... |
| `instanceSizeIn` / `instanceSizeNotIn` | Lista de tamaños a incluir/excluir. |
| `instanceGeneration` | Generación mínima (operador `Gt`). |
| `allZones` | `true` añade `topology.kubernetes.io/zone: Exists`. |
| `taints` | Taints del NodePool (GPU). |
| `extraRequirements` | Requirements adicionales en bruto. |
| `limits` | `cpu`, `memory`, `nvidia.com/gpu`... |
| `consolidationPolicy` | `WhenEmpty` / `WhenEmptyOrUnderutilized`. |
| `consolidateAfter` | p. ej. `1m`, `2m`. |
| `budgets` | Lista de disruption budgets. |
| `extraLabels` | Labels extra del objeto NodePool. |

---

## ¿Kustomize o Helm?

| Criterio | Kustomize | Helm |
|----------|-----------|------|
| Sin plantillas (overlays declarativos) | ✅ | ❌ (usa templating) |
| Parametrización dinámica (bucles, condicionales) | limitado | ✅ |
| Integrado en `kubectl` | ✅ (`-k`) | requiere `helm` |
| Reutilizar un mismo chart para N NodePools | — | ✅ (lista `nodePools`) |

Ambas producen los mismos recursos. Elige según tu flujo de GitOps (Argo CD y Flux soportan las dos).

---

🏠 [Volver al README principal](../README.md)
