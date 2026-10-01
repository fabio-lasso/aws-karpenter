# 04.3 · Consolidación

## `consolidationPolicy: WhenEmpty`

En la sección anterior configuramos el NodePool `custom` con `consolidationPolicy: WhenEmpty` y `consolidateAfter: 30s`. Esto indica a Karpenter que elimine los nodos vacíos tras expirar el timeout.

## `consolidationPolicy: WhenEmptyOrUnderutilized`

Con esta política, Karpenter reduce activamente el costo del clúster: identifica cuándo un nodo puede eliminarse (sus cargas corren en otros nodos) y cuándo puede reemplazarse por una variante más económica. `consolidateAfter` indica cuánto esperar antes de consolidar tras añadir o quitar un pod.

## Actualizar el NodePool a `WhenEmptyOrUnderutilized`

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
    consolidateAfter: 30s
    budgets:
    - nodes: 10%
EOF
```

> Disponible también en [`manifests/nodepool-custom-ondemand.yaml`](../../manifests/nodepool-custom-ondemand.yaml).

> [!IMPORTANT]
> Cuando la consolidación está habilitada (`WhenEmptyOrUnderutilized`), se recomienda configurar `requests = limits` para los recursos distintos de CPU. Si varios pods con límite de memoria mayor que su request hacen *burst* a la vez, pueden terminar por OOM. La consolidación lo hace más probable porque empaqueta pods considerando solo sus requests.

## Reto

Prepara el entorno escalando `inflate` a 3 réplicas (provisiona un nodo pequeño) y luego a 10:

```bash
kubectl scale deployment inflate --replicas 3
# espera a que haya 3 nodos...
kubectl scale deployment inflate --replicas 10
```

Deberían existir 4 nodos: 2 del NodePool `system` y 2 del `custom`.

Preguntas:

1. **Escalar a 6 réplicas, ¿qué ocurre?** → Karpenter puede consolidar reemplazando nodos por variantes más pequeñas/económicas acordes a la nueva demanda.
2. **¿Qué ocurre al bajar a 3 réplicas?** → Más consolidación: nodos se eliminan o reemplazan por instancias menores.
3. **Con 10 réplicas, ¿qué pasa si el NodePool admite on-demand y spot?** → Karpenter puede migrar de on-demand a spot para reducir costo (consolidación tipo *Delete*).
4. **Escalar a 1 réplica, ¿qué ocurre?** → Consolidación agresiva hacia un único nodo pequeño.
5. **¿Qué otros escenarios impiden la consolidación?** → Pods sin PDB adecuados, anotación `karpenter.sh/do-not-disrupt`, DaemonSets, pods con almacenamiento local, etc.
6. **Escalar a 0** (preparación para la siguiente sección):

```bash
kubectl scale deployment inflate --replicas 0
```

## Qué aprendimos

- Karpenter puede consolidar cargas con `consolidationPolicy: WhenEmptyOrUnderutilized`.
- La consolidación reduce costo en dos situaciones: **Delete** (la capacidad de un nodo se redistribuye con seguridad) y **Replace** (un nodo se reemplaza por otro más pequeño).
- Considera múltiples nodos pero actúa sobre uno a la vez, eligiendo el que minimiza la disrupción.
- La consolidación tipo Delete incluye mover instancias de on-demand a spot, pero Karpenter **no** dispara Replace para hacer un nodo Spot más pequeño (evita aumentar las interrupciones).
- Karpenter añade un *finalizer* para que un `kubectl delete node` resulte en una terminación grácil y segura.

---

⬅️ Anterior: [Aprovisionamiento automático](02-aprovisionamiento-automatico.md) · ➡️ Siguiente: [Despliegues Spot](04-spot.md)
