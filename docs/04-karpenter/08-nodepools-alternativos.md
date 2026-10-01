# 04.8 · Uso de NodePools alternativos

Cada NodePool provee una configuración única que define los recursos que soporta, además de labels y taints que se aplican a los nodos que crea. En clústeres grandes, nuevas aplicaciones pueden necesitar nodos con taints o labels específicos. Para este workshop ya definimos el NodePool `team1`.

```bash
kubectl get nodepools
```

## Deployment que usa el NodePool `team1`

```bash
cat <<EOF > inflate-team1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate-team1
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate-team1
  template:
    metadata:
      labels:
        app: inflate-team1
    spec:
      nodeSelector:
        intent: apps
        kubernetes.io/arch: amd64
        karpenter.sh/nodepool: team1
      containers:
      - image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
        name: inflate-team1
        resources:
          requests:
            cpu: "1"
            memory: 256M
      tolerations:
      - key: team1
        operator: Exists
      topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app: inflate-team1
        maxSkew: 1
        minDomains: 3
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
EOF
kubectl apply -f inflate-team1.yaml
```

### Explicación

- `intent: apps` → coloca el pod en nodos con ese label.
- `karpenter.sh/nodepool: team1` → indica a Karpenter qué NodePool usar para aprovisionar capacidad.
- `kubernetes.io/arch: amd64` → instancias x86_64.
- La **toleration** de `team1` es obligatoria porque los nodos de `team1` llevan el taint `team1:NoSchedule`. `NoSchedule` significa que solo las apps con esa toleration pueden ubicarse ahí.
- **topologySpreadConstraints** reparte los pods entre zonas de disponibilidad.

## Reto

1. **Escalar a 4 réplicas** → `kubectl scale deployment inflate-team1 --replicas 4`
2. **¿Qué NodePool y qué nodos eligió Karpenter?** → `team1`, instancias On-Demand amd64.
3. **¿Por qué dividió en varios nodos en lugar de empaquetar?** → Por el `topologySpreadConstraints` con `minDomains: 3`, que fuerza distribución entre al menos 3 zonas.
4. **Escalar a 0**:

```bash
kubectl scale deployment inflate-team1 --replicas 0
```

## Qué aprendimos

- Las aplicaciones con labels o taints específicos pueden usar NodePools alternativos personalizados. Es un patrón común en clústeres grandes.
- Los pods seleccionan el NodePool con el label `karpenter.sh/nodepool`.
- Karpenter soporta [topologySpreadConstraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) para equilibrar pods entre zonas de disponibilidad.

---

⬅️ Anterior: [Multiarquitectura](07-multiarquitectura.md) · ➡️ Siguiente: [Disruption Budgets](09-disruption-budgets.md)
