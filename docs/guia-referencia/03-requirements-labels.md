# Guía de referencia · Requirements y well-known labels

Los `requirements` de un NodePool acotan qué instancias EC2 puede lanzar Karpenter. Cada requirement combina una **key** (label well-known), un **operator** y, según el operador, unos **values**.

> [!NOTE]
> EKS Auto Mode usa **labels distintos** de Karpenter *self-managed*. Las labels de las *EC2 managed instances* empiezan con `eks.amazonaws.com/`. Las labels de arquitectura, zona y capacidad siguen las convenciones estándar de Kubernetes/Karpenter.

## Operadores

| Operador | Uso | Ejemplo |
|----------|-----|---------|
| `In` | El valor del nodo está en la lista | `values: ["spot"]` |
| `NotIn` | El valor NO está en la lista | `values: [nano, micro]` |
| `Exists` | La label existe (cualquier valor) | para "todas las AZ" |
| `DoesNotExist` | La label no existe | |
| `Gt` | Mayor que (un valor numérico) | generación `> 2` |
| `Lt` | Menor que (un valor numérico) | |

---

## Labels estándar (Kubernetes / Karpenter)

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `topology.kubernetes.io/zone` | `us-east-2a` | Zona de disponibilidad. Usa `Exists` para permitir todas. |
| `node.kubernetes.io/instance-type` | `g4dn.8xlarge` | Tipo de instancia EC2 exacto. |
| `kubernetes.io/arch` | `amd64` / `arm64` | Arquitectura de CPU (`arm64` = Graviton). |
| `karpenter.sh/capacity-type` | `spot` | Tipo de capacidad: `spot`, `on-demand`, `reserved`. |

> **`karpenter.sh/capacity-type`**: si **no** lo especificas, Karpenter prioriza en este orden: **reserved → spot → on-demand**. Puedes forzar uno concreto por NodePool (estrategia Spot amplio / On-Demand fallback) o por pod.

---

## Labels específicas de EKS Auto Mode (`eks.amazonaws.com/`)

### Clasificación de instancias

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `eks.amazonaws.com/instance-category` | `g` | Categoría (letra antes del número de generación): `c`, `m`, `r`, `t`, `g`, `p`, etc. |
| `eks.amazonaws.com/instance-generation` | `4` | Número de generación dentro de la categoría. Útil con `Gt` para exigir generaciones modernas. |
| `eks.amazonaws.com/instance-family` | `g4dn` | Familia (categoría + generación + sufijos). |
| `eks.amazonaws.com/instance-size` | `8xlarge` | Tamaño. Útil con `NotIn` para excluir los pequeños. |

### CPU y memoria

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `eks.amazonaws.com/instance-cpu` | `32` | Número de vCPUs. |
| `eks.amazonaws.com/instance-cpu-manufacturer` | `aws` | Fabricante de CPU (`aws` = Graviton, `intel`, `amd`). |
| `eks.amazonaws.com/instance-memory` | `131072` | Memoria en MiB. |

### Red y almacenamiento

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `eks.amazonaws.com/instance-hypervisor` | `nitro` | Hipervisor de la instancia. |
| `eks.amazonaws.com/instance-ebs-bandwidth` | `9500` | Ancho de banda EBS máximo (Mbps). |
| `eks.amazonaws.com/instance-network-bandwidth` | `131072` | Ancho de banda de red base (Mbps). |
| `eks.amazonaws.com/instance-local-nvme` | `900` | Almacenamiento NVMe local (GiB). |
| `eks.amazonaws.com/instance-encryption-in-transit-supported` | `true` | Soporte de cifrado en tránsito. |

### GPU / aceleradores

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `eks.amazonaws.com/instance-gpu-name` | `t4` | Nombre de la GPU. |
| `eks.amazonaws.com/instance-gpu-manufacturer` | `nvidia` | Fabricante de la GPU. |
| `eks.amazonaws.com/instance-gpu-count` | `1` | Número de GPUs. |
| `eks.amazonaws.com/instance-gpu-memory` | `16384` | Memoria de la GPU (MiB). |

### Otras

| Label | Ejemplo | Descripción |
|-------|---------|-------------|
| `eks.amazonaws.com/compute-type` | `auto` | Identifica nodos gestionados por EKS Auto Mode. Útil para dirigir/filtrar workloads. |
| `eks.amazonaws.com/capacity-reservation-interruptible` | `true` | Si la reserva de capacidad es interrumpible. Solo en nodos `capacity-type: reserved`. |

---

## Patrones de uso

### Spot amplio (maximizar diversidad)

```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot"]
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64", "arm64"]
  - key: eks.amazonaws.com/instance-category
    operator: In
    values: ["c", "m", "r", "t"]
  - key: eks.amazonaws.com/instance-size
    operator: NotIn
    values: [nano, micro, small, medium]
  - key: eks.amazonaws.com/instance-generation
    operator: Gt
    values: ["2"]
  - key: topology.kubernetes.io/zone
    operator: Exists
```

### On-Demand justo (predecible)

```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand"]
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64"]
  - key: eks.amazonaws.com/instance-category
    operator: In
    values: ["c", "m"]
  - key: eks.amazonaws.com/instance-size
    operator: In
    values: [xlarge, 2xlarge]
```

### Seleccionar por número de CPU

```yaml
requirements:
  - key: eks.amazonaws.com/instance-cpu
    operator: In
    values: ["4", "8", "16", "32"]
```

### Solo Graviton (ARM64)

```yaml
requirements:
  - key: kubernetes.io/arch
    operator: In
    values: ["arm64"]
  # o explícitamente por fabricante:
  - key: eks.amazonaws.com/instance-cpu-manufacturer
    operator: In
    values: ["aws"]
```

### GPU NVIDIA

```yaml
requirements:
  - key: eks.amazonaws.com/instance-gpu-manufacturer
    operator: In
    values: ["nvidia"]
  - key: eks.amazonaws.com/instance-gpu-count
    operator: Gt
    values: ["0"]
```

---

## Opciones de compra de capacidad

EKS Auto Mode y Karpenter soportan cuatro opciones y **siempre aprovisionan primero la capacidad reservada**, seguida de Spot u On-Demand:

| Opción (`capacity-type`) | Descripción |
|--------------------------|-------------|
| `reserved` | Capacity Blocks y On-Demand Capacity Reservations (ODCR). Se usa primero. |
| `spot` | Capacidad sobrante, hasta ~90% de descuento, interrumpible. |
| `on-demand` | Capacidad bajo demanda, precio fijo, no interrumpible. |

> Las ODCR/Capacity Blocks se seleccionan en la NodeClass con `capacityReservationSelectorTerms` (ver [02-nodeclass.md](02-nodeclass.md)).

---

⬅️ [NodeClass](02-nodeclass.md) · ➡️ [Workload](04-workload.md)
