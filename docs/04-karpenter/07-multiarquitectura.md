# 04.7 · Despliegues multiarquitectura (AWS Graviton)

Desplegaremos una aplicación que inicialmente usa solo On-Demand sobre arquitectura `amd64`. El objetivo es construir un clúster EKS eficiente con Karpenter, EC2 Spot y **AWS Graviton** (`arm64`).

> [!IMPORTANT]
> Los procesadores [AWS Graviton](https://aws.amazon.com/ec2/graviton/) son de 64-bit Arm Neoverse. Impulsan instancias como R8g, R7g, M7g, M6g, T4g, C7g, C6g, R6g, X2gd, etc. Ofrecen hasta **40% mejor relación precio/rendimiento** que instancias x86 comparables.

Para usar Graviton como host de contenedores, la imagen base y el software (incluidos sidecars y DaemonSets) deben soportar `arm64`. No puedes correr imágenes `amd64` en host `arm64` ni viceversa. Trata las imágenes como binarios dependientes de la arquitectura de CPU. Muchas herramientas soportan ambas vía imágenes **multi-arquitectura (multi-arch)**; registries como Docker Hub, Quay y Amazon ECR las soportan.

## Actualizar el NodePool `custom` (solo On-Demand amd64)

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
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
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
```

## Deployment en instancias amd64 (x86_64)

```bash
cat <<EOF > inflate-efficient.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate-efficient
spec:
  selector:
    matchLabels:
      app: inflate-efficient
  replicas: 0
  template:
    metadata:
      labels:
        app: inflate-efficient
    spec:
      nodeSelector:
        intent: apps
        kubernetes.io/arch: amd64
        karpenter.sh/capacity-type: on-demand
      containers:
      - image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        name: inflate-efficient
        resources:
          requests:
            cpu: "1"
            memory: 515Mi
EOF
kubectl apply -f inflate-efficient.yaml
```

Usamos `kubernetes.io/arch` como `nodeSelector` para indicar a Karpenter la arquitectura de CPU requerida.

## Reto

1. **Escalar a 10 réplicas; ¿qué nodos eligió Karpenter?** → `kubectl scale deployment inflate-efficient --replicas 10`. Instancias On-Demand amd64 diversificadas.
2. **Costo mensual estimado** → visible en `eks-node-viewer`.
3. **Cambiar las restricciones del Deployment a solo Graviton** → cambia el `nodeSelector` a `kubernetes.io/arch: arm64`.
4. **Costo mensual estimado tras Graviton** → menor que x86.
5. **Reducir el request de CPU a 256m** → tras redesplegar, Karpenter puede consolidar hacia instancias más pequeñas.
6. **Costo mensual estimado** → aún menor.
7. **Permitir Spot en el NodePool** → Karpenter termina la On-Demand al encontrar una Spot más económica.
8. **Costo mensual estimado** → el más bajo.
9. **Escalar a 0**:

```bash
kubectl scale deployment inflate-efficient --replicas 0
```

## Qué aprendimos

- Karpenter usa *well-known labels* en el `nodeSelector` de los pods para condicionar la instancia elegida (aquí `kubernetes.io/arch` para amd64/arm64).
- Karpenter diversifica también On-Demand, eligiendo con la estrategia **lowest-price** la instancia que mejor empaqueta los pods.
- Sé intencional con las restricciones de los pods. Si eres flexible entre arquitecturas y no especificas, delegas la decisión a Karpenter según las restricciones del NodePool.
- Igual que la arquitectura, puedes dejar el NodePool abierto a On-Demand o Spot y dejar que `karpenter.sh/capacity-type` del pod decida. Si no se especifica, Karpenter elige según requisitos y precio.
- Configura requests adecuados. Herramientas: [AWS Split Cost Allocation Data](https://docs.aws.amazon.com/cur/latest/userguide/split-cost-allocation-data.html), [Kubecost](https://www.kubecost.com/), [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) en modo recomendación.

### Recursos sobre Graviton

- [Migrating x86-based applications to AWS Graviton Processors (Workshop)](https://catalog.workshops.aws/)
- [Karpenter Blueprints: Working with Graviton Instances](https://github.com/aws-samples/karpenter-blueprints)

---

⬅️ Anterior: [Múltiples NodePools](06-multiples-nodepools.md) · ➡️ Siguiente: [NodePools alternativos](08-nodepools-alternativos.md)
