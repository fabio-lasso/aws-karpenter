# 04.9 · Presupuestos de disrupción (NodePool Disruption Budgets)

> [!TIP]
> Aprende más en la sección [Disruption](https://karpenter.sh/docs/concepts/disruption/) de la documentación de Karpenter.

Las acciones de Karpenter (consolidación, detección de *drift*, `expireAfter`, `terminationGracePeriod`) optimizan costo, aplican parches de seguridad y aseguran gobernanza, pero causan cierto nivel de disrupción. Para controlar ese equilibrio se usan **disruption budgets** en la configuración del NodePool, que limitan la tasa a la que Karpenter interrumpe nodos cuando están vacíos, han sufrido drift o están subutilizados.

Combinando disruption budgets con **Pod Disruption Budgets (PDBs)** obtienes controles de disrupción voluntaria tanto a nivel de aplicación como de plataforma.

Si no se configura ningún budget, hay uno por defecto de `nodes: 10%`. Si hay varios budgets, Karpenter honra el **más restrictivo**. Un budget sin `reasons` aplica a todas las razones.

Razones de disrupción configurables:

| Razón | Significado |
|-------|-------------|
| `Empty` | El nodo está vacío |
| `Underutilized` | El nodo está subutilizado y puede eliminarse o reemplazarse por uno más pequeño |
| `Drifted` | El nodo difiere de su estado deseado (p. ej. AMI) |

## Actualizar el NodePool con un budget para nodos subutilizados

Aquí fijamos tasa `0` para `Underutilized` y `100%` para el resto.

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
          values: ["on-demand"]
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
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 0s
    budgets:
      - nodes: "0"
        reasons:
          - "Underutilized"
      - nodes: "100%"
EOF
```

## Deployment con distribución multi-AZ

```bash
cat <<EOF > inflate-multiaz.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate-multiaz
spec:
  replicas: 10
  selector:
    matchLabels:
      app: inflate-multiaz
  template:
    metadata:
      labels:
        app: inflate-multiaz
    spec:
      nodeSelector:
        intent: apps
      containers:
      - image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
        name: inflate-multiaz
        resources:
          requests:
            cpu: "2"
            memory: "6Gi"
      topologySpreadConstraints:
        - labelSelector:
            matchLabels:
              app: inflate-multiaz
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          minDomains: 3
EOF
kubectl apply -f inflate-multiaz.yaml
```

## Reto

Visualiza el entorno:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool,topology.kubernetes.io/zone -node-selector intent=apps -resources cpu,memory

kubectl get node --selector=intent=apps -L kubernetes.io/arch -L node.kubernetes.io/instance-type -L karpenter.sh/nodepool -L topology.kubernetes.io/zone -L karpenter.sh/capacity-type
```

Debido al `topologySpreadConstraints` con `minDomains: 3`, habrá al menos un nodo por zona (típicamente 4 nodos).

1. **Escalar a 3 réplicas: ¿se reemplazaron los nodos subutilizados?** → No, porque el budget para `Underutilized` es `0`.
2. **Cambiar el budget `Underutilized` a `1`: ¿cómo se reemplazan?** → De uno en uno, de forma controlada.
3. **Escalar a 0** (preparación):

```bash
kubectl scale deployment inflate-multiaz --replicas 0
```

## Qué aprendimos

- Los **Disruption Budgets** controlan la tasa y el número de disrupciones por distintas razones.
- Se configuran en el NodePool con budgets específicos por razón.
- Un budget de `"0"` impide disrupciones por esa razón; `"100%"` permite reemplazar todos los nodos afectados a la vez; `"1"` fuerza reemplazos de uno en uno (más controlado).
- Proporcionan una forma flexible de gestionar el escalado y la optimización del clúster.

Ejemplos adicionales en el repositorio [Karpenter Blueprints](https://github.com/aws-samples/karpenter-blueprints).

---

⬅️ Anterior: [NodePools alternativos](08-nodepools-alternativos.md) · ➡️ Siguiente: [Debugging](10-debugging.md)
