# 04.6 · Desplegar múltiples NodePools

En clústeres grandes con múltiples aplicaciones, algunas pueden necesitar nodos con taints o labels específicos. En esos casos puedes configurar NodePools alternativos. Aquí sobrescribimos `custom` y creamos un nuevo NodePool `team1`.

> [!TIP]
> Lee más sobre la configuración del CRD NodePool para el proveedor AWS en la [documentación de Karpenter](https://karpenter.sh/docs/concepts/nodepools/).

## Actualizar el NodePool `custom`

```bash
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: custom
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: custom
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: eks.amazonaws.com/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64","arm64"]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
---
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: custom
spec:
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "karpenter-workshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "karpenter-workshop"
  role: "\$NODE_IAM_ROLE"
  tags:
    Name: karpenter.sh/nodepool/custom
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF
```

## Crear el NodePool `team1`

```bash
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: team1
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: team1
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: eks.amazonaws.com/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64","arm64"]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["2"]
      taints:
        - effect: NoSchedule
          key: team1
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
---
apiVersion: eks.amazonaws.com/v1
kind: NodeClass
metadata:
  name: team1
spec:
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "karpenter-workshop"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "karpenter-workshop"
  role: "\$NODE_IAM_ROLE"
  tags:
    Name: karpenter.sh/nodepool/team1
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF
```

## Puntos clave de la configuración

- Ambos NodePools ponen el label `intent: apps`. Los Deployments con ese label serán gestionados por cualquiera de los dos según los requisitos.
- Ambos permiten `amd64` (equivalente a x86_64) y `arm64`.
- `custom` soporta **spot y on-demand**; `team1` solo **on-demand**.
- `team1` solo admite pods/jobs que **toleren** la key `team1`. Los nodos de este NodePool reciben el taint `team1:NoSchedule`.
- `team1` define una NodeClass distinta en cuanto a los tags.

> [!IMPORTANT]
> Si Karpenter encuentra un taint en el NodePool que un pod no tolera, no usará ese NodePool para ese pod. Se recomienda crear NodePools **mutuamente exclusivos**. Si varios NodePools coinciden, Karpenter elige uno al azar.

## Verificar

```bash
kubectl get nodepools
kubectl describe nodepools custom
kubectl get NodeClass
```

---

⬅️ Volver: [04 · Karpenter](README.md) · ➡️ Siguiente: [Multiarquitectura](07-multiarquitectura.md)
