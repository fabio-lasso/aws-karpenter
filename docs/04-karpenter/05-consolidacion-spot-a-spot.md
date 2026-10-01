# 04.5 · Consolidación Spot-a-Spot

La **consolidación Spot-a-Spot** permite a Karpenter reemplazar activamente una instancia Spot por otra más económica. A diferencia de la consolidación On-Demand (donde la métrica principal es el precio más bajo y la reserva de nodo), la estrategia Spot-a-Spot necesita **diversidad** de instancias (tipos, tamaños y zonas).

> [!IMPORTANT]
> Mientras haya al menos **15 instancias seleccionables**, Karpenter puede reemplazar una Spot por otra con mejor relación costo/baja frecuencia de interrupciones. Sin esta restricción, Karpenter podría elegir instancias con menor disponibilidad y mayor frecuencia de interrupción.

## NodePool restringido (para demostrar la limitación)

Restringimos el NodePool a la categoría `c`, tamaño `4xlarge`, solo Spot. Esto demuestra que un nodo Spot **no** puede consolidarse porque no hay 15 tipos de instancia en la selección.

```bash
cat <<EOF > nodepool.yaml
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
      expireAfter: 336h
      terminationGracePeriod: 24h
      nodeClassRef:
        group: eks.amazonaws.com
        kind: NodeClass
        name: custom
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: eks.amazonaws.com/instance-category
          operator: In
          values: ["c"]
        - key: eks.amazonaws.com/instance-size
          operator: In
          values: [4xlarge]
        - key: eks.amazonaws.com/instance-generation
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 0s
EOF
kubectl apply -f nodepool.yaml
```

> Disponible también en [`manifests/nodepool-spot-constrained.yaml`](../../manifests/nodepool-spot-constrained.yaml).

Despliega la aplicación `inflate` con 10 réplicas (ver [`manifests/inflate.yaml`](../../manifests/inflate.yaml), aquí con `replicas: 10`, `terminationGracePeriodSeconds: 0` y `securityContext`).

Comprueba el tipo de instancia lanzado:

```bash
kubectl get nodes -L karpenter.sh/nodepool -L node.kubernetes.io/instance-type -L topology.kubernetes.io/zone -L karpenter.sh/capacity-type --selector=intent=apps
```

```
NAME                  STATUS   ROLES    AGE   VERSION               NODEPOOL   INSTANCE-TYPE   ZONE         CAPACITY-TYPE
i-007fa6b5492e94dcf   Ready    <none>   24s   v1.32.1-eks-b9364f6   custom     c6a.4xlarge     us-east-2b   spot
```

> [!NOTE]
> Puedes ver tipos de instancia distintos: depende de la disponibilidad y el precio Spot vigente.

### Inspeccionar el NodeClaim

Karpenter usa la estrategia **price-capacity-optimized** al llamar a la API EC2 Fleet. Para ver los tipos de instancia considerados:

```bash
kubectl get nodeclaims
kubectl get nodeclaim/<claim-name> -o yaml
```

En `.spec.requirements` verás varias instancias de la serie `c` tamaño `4xlarge` (c4, c5, c5a, c6a, c6i, c7a, c7i, etc.).

Para disparar una consolidación, escala de 10 a 5:

```bash
kubectl scale --replicas=5 deployment/inflate
```

## Reto

1. **¿Viste consolidación al reducir réplicas?** → Sí para Delete, pero no Spot-a-Spot con el NodePool restringido.
2. **¿Por qué no hubo consolidación Spot-a-Spot?** → Porque la selección tiene menos de 15 tipos de instancia.
3. **¿Qué pasa si amplías la selección de instancias?** → Al no restringir, hay ≥15 instancias y Karpenter puede hacer Spot-a-Spot.
4. **¿Qué ocurre al subir a 10 réplicas?** → Se aprovisionan más nodos Spot diversificados.
5. **¿Qué ocurre al bajar a 5?** → Consolidación, posiblemente reemplazando por una instancia Spot más pequeña.
6. **¿Qué instancia se lanzó por la consolidación Spot-a-Spot?** → Revisa con el comando `kubectl get nodes -L ...`.
7. **Escalar a 0**:

```bash
kubectl scale deployment inflate --replicas 0
```

## Qué aprendimos

- Karpenter puede reemplazar un nodo Spot por otro más económico cuando hay **al menos 15 instancias seleccionables** que equilibran precio y disponibilidad.
- **Evita restringir en exceso los tipos de instancia**: la estrategia price-capacity-optimized equilibra precio y disponibilidad de capacidad sobrante. A mayor diversidad, mayor probabilidad de obtener capacidad Spot a escala con menor frecuencia de interrupciones y menor costo.
- **Maneja grácilmente interrupciones y consolidaciones**: Karpenter consume eventos de una cola Amazon SQS poblada por Amazon EventBridge y drena el nodo interrumpido mientras aprovisiona uno nuevo.
- **Configura requests y limits cuidadosamente**: el dimensionamiento correcto es responsabilidad compartida. Karpenter no considera *limits* ni la utilización real. Herramientas útiles: [Kubecost](https://www.kubecost.com/), [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) en modo recomendación, o [Goldilocks](https://github.com/FairwindsOps/goldilocks).

---

⬅️ Anterior: [Despliegues Spot](04-spot.md) · ➡️ Volver: [04 · Karpenter](README.md)
