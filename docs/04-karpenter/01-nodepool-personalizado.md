# 04.1 · Configurar un NodePool personalizado

La configuración de Karpenter se expresa como un recurso personalizado (CR) **NodePool**. Un único NodePool puede manejar muchas formas de pods distintas. Karpenter toma decisiones de scheduling y aprovisionamiento según atributos de los pods (labels, affinity). Un clúster puede tener varios NodePools (además de los que trae EKS Auto Mode) para servir a distintas necesidades.

Uno de los objetivos principales de Karpenter es simplificar la gestión de capacidad mediante un enfoque **group-less** (sin grupos de nodos).

## Desplegar un NodePool personalizado

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
      expireAfter: 336h
      terminationGracePeriod: 24h
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: eks.amazonaws.com/instance-size
          operator: NotIn
          values: [nano, micro, small, medium, large]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    budgets:
    - nodes: 10%
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

> Este manifiesto también está disponible en [`manifests/nodepool-custom-spot.yaml`](../../manifests/nodepool-custom-spot.yaml).

Verifica el NodePool:

```bash
kubectl get nodepool
```

## Explicación de los campos

La configuración se divide en dos partes: la especificación del **NodePool** y la implementación del proveedor (**NodeClass**).

- **requirements**: define propiedades de los nodos como tipo de instancia y zona de disponibilidad. En este ejemplo se fija `karpenter.sh/capacity-type` para obtener instancias Spot y `eks.amazonaws.com/instance-size` para evitar instancias pequeñas. Consulta las [etiquetas soportadas](https://karpenter.sh/docs/concepts/scheduling/).
- **disruption**: describe qué nodos considera Karpenter para consolidación. Las políticas son `WhenEmpty` y `WhenEmptyOrUnderutilized`. Los *disruption budgets* controlan cuántas disrupciones se permiten a la vez (aquí, 10% de los nodos).
- **expireAfter** y **terminationGracePeriod**: `expireAfter` es el tiempo que un nodo puede vivir antes de ser removido (respetando Pod Disruption Budgets, `terminationGracePeriodSeconds` y la anotación `karpenter.sh/do-not-disrupt`). `terminationGracePeriod` es el tiempo máximo de *draining* antes de forzar el borrado. En este ejemplo: expiran a los 14 días con 24 h de gracia. Los nodos de EKS Auto Mode tienen una vida máxima de 21 días.
- **limits**: límite de CPU y memoria asignados a ese NodePool.
- **NodeClass**: ajustes específicos de AWS (subnets, security groups, tags, rol IAM del nodo). Cada NodePool referencia una NodeClass vía `spec.template.spec.nodeClassRef`. Varios NodePools pueden apuntar a la misma NodeClass.

---

⬅️ Volver: [04 · Karpenter](README.md) · ➡️ Siguiente: [Aprovisionamiento automático](02-aprovisionamiento-automatico.md)
