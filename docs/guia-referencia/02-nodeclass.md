# Guía de referencia · NodeClass

La **NodeClass** define los ajustes a **nivel de infraestructura** que se aplican a los nodos: red (subnets, security groups), rol IAM, almacenamiento, etiquetado, cifrado y opciones de red avanzadas. Un NodePool referencia una NodeClass vía `nodeClassRef`.

`apiVersion: eks.amazonaws.com/v1` · `kind: NodeClass` *(para EKS Auto Mode)*

> ⚠️ En Karpenter *self-managed* el recurso equivalente es `EC2NodeClass` (`apiVersion: karpenter.k8s.aws/v1`) y algunos campos difieren (p. ej. `amiSelectorTerms`, `blockDeviceMappings`, `userData`). Esta guía cubre la **NodeClass de EKS Auto Mode**.

## Estructura general

```yaml
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: <nombre>
spec:
  subnetSelectorTerms: [ ... ]
  securityGroupSelectorTerms: [ ... ]
  role: <nombre-del-rol-iam>
  ephemeralStorage: { size, iops, throughput }
  tags: { ... }
  # Opcionales avanzados:
  podSubnetSelectorTerms: [ ... ]
  podSecurityGroupSelectorTerms: [ ... ]
  capacityReservationSelectorTerms: [ ... ]
  snatPolicy: <Random | Disabled>
  networkPolicy: <DefaultAllow | DefaultDeny>
  networkPolicyEventLogs: <Disabled | Enabled>
  kmsKeyID: <arn|id|alias>
  advancedNetworking: { ... }
```

---

## Selección de red

### `subnetSelectorTerms`

**Obligatorio.** Selecciona en qué **subnets** se lanzarán los nodos. Puedes seleccionar por `tags` o por `id`.

```yaml
subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: "mi-cluster"   # descubrimiento por tag
  # - id: "subnet-0123456789abcdef0"          # alternativa por ID directo
```

> **Buena práctica:** usa subnets **privadas** para los nodos (mayor seguridad). El tag `karpenter.sh/discovery` es la convención habitual.

### `securityGroupSelectorTerms`

**Obligatorio.** Selecciona los **security groups** que se asociarán a los nodos.

```yaml
securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: "mi-cluster"
  # - id: "sg-0123456789abcdef0"
  # - name: "eks-cluster-security-group"
```

---

## `role`

**Obligatorio.** Nombre del **rol IAM** que asumirán los nodos (el perfil de instancia). En EKS Auto Mode suele ser el rol de nodo creado para el clúster.

```yaml
role: "mi-cluster-eks-node-role"
```

> Si creas una NodeClass personalizada, debes crear un **EKS Access Entry** de tipo `EC2` para que los nodos puedan unirse al clúster, y asociar la política `AmazonEKSAutoNodePolicy`.

```bash
aws eks create-access-entry --cluster-name <cluster> --principal-arn <node-role-arn> --type EC2
aws eks associate-access-policy --cluster-name <cluster> --principal-arn <node-role-arn> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy \
  --access-scope type=cluster
```

---

## `ephemeralStorage`

Configura el **almacenamiento efímero** (volumen raíz EBS) de los nodos. Útil para cargas sensibles a I/O o con imágenes grandes.

```yaml
ephemeralStorage:
  size: "80Gi"      # Rango: 1-59000Gi / 1-64000G / 1-58Ti / 1-64T
  iops: 3000        # Rango: 3000-16000
  throughput: 125   # Rango: 125-1000 (MiB/s)
```

| Campo | Descripción |
|-------|-------------|
| `size` | Tamaño del volumen efímero. |
| `iops` | IOPS aprovisionadas (volúmenes gp3). |
| `throughput` | Rendimiento en MiB/s. |

---

## `tags`

**Tags de AWS** que se aplican a las instancias EC2 creadas. Clave para **asignación de costos** y gobernanza.

```yaml
tags:
  Name: karpenter.sh/nodeclass/prod
  environment: prod
  managed-by: karpenter
  cost-center: engineering-prod
```

---

## `kmsKeyID`

Clave KMS para **cifrar** el volumen de los nodos. Acepta Key ID, ARN, alias o alias ARN.

```yaml
kmsKeyID: "arn:aws:kms:region:account:key/key-id"
```

---

## Red avanzada

### `podSubnetSelectorTerms` / `podSecurityGroupSelectorTerms`

Permiten colocar los **pods en subnets/security groups separados** de los nodos (red avanzada). Si usas `podSubnetSelectorTerms`, debes incluir también `podSecurityGroupSelectorTerms`.

```yaml
podSubnetSelectorTerms:
  - tags:
      kubernetes.io/role/pod: "1"
podSecurityGroupSelectorTerms:
  - tags:
      Name: "eks-pod-sg"
```

### `snatPolicy`

Política de SNAT para el tráfico saliente de los pods: `Random` (por defecto) o `Disabled`.

### `networkPolicy` / `networkPolicyEventLogs`

| Campo | Valores | Descripción |
|-------|---------|-------------|
| `networkPolicy` | `DefaultAllow` / `DefaultDeny` | Comportamiento por defecto de las Network Policies. |
| `networkPolicyEventLogs` | `Disabled` / `Enabled` | Habilita logs de eventos de las Network Policies. |

### `advancedNetworking`

```yaml
advancedNetworking:
  associatePublicIPAddress: false   # IP pública en instancias (por defecto: según la subnet)
  httpsProxy: http://192.0.2.4:3128 # proxy forward (requiere a menudo certificateBundles)
  noProxy:                          # dominios/hosts excluidos del proxy (máx 50)
    - localhost
    - 127.0.0.1
    - 169.254.169.254               # EC2 Instance Metadata Service
    - .internal
    - .eks.amazonaws.com
  ipv4PrefixSize: Auto              # "Auto" (prefix delegation) o "32" (secondary IP mode)
```

| Campo | Descripción |
|-------|-------------|
| `associatePublicIPAddress` | Asigna IP pública a los nodos. Si no se define, hereda el `MapPublicIpOnLaunch` de la subnet. |
| `httpsProxy` | Proxy forward para el tráfico HTTPS de los nodos. |
| `noProxy` | Lista de hosts/dominios que **no** pasan por el proxy (incluye el IMDS y endpoints VPC). |
| `ipv4PrefixSize` | `Auto` usa *prefix delegation* (/28, 16 IPs por nodo); `"32"` usa *secondary IP mode* (1 IP por pod), mejor para cargas *pod-sparse* a gran escala. |

---

## `capacityReservationSelectorTerms`

Selecciona **On-Demand Capacity Reservations (ODCR)** o *Capacity Blocks* que EKS Auto Mode priorizará al aprovisionar.

```yaml
capacityReservationSelectorTerms:
  - id: cr-56fac701cc1951b03
  - tags:
      Name: "targeted-odcr"
    owner: "012345678901"    # filtro opcional por cuenta propietaria
```

---

## Ejemplo completo comentado

```yaml
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: prod
spec:
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "mi-cluster"    # subnets privadas descubiertas por tag
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "mi-cluster"
  role: "mi-cluster-eks-node-role"              # rol IAM del nodo
  ephemeralStorage:
    size: "80Gi"
    iops: 3000
    throughput: 125
  tags:
    Name: karpenter.sh/nodeclass/prod
    environment: prod
    managed-by: karpenter
    cost-center: engineering-prod
```

---

⬅️ [NodePool](01-nodepool.md) · ➡️ [Requirements y labels](03-requirements-labels.md)
