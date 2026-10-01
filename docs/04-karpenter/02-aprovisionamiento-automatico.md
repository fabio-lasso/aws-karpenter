# 04.2 · Aprovisionamiento automático de nodos

En esta sección crearás pods mediante un Deployment y observarás cómo Karpenter aprovisiona nodos en respuesta.

## Crear el Deployment

```bash
cat <<EOF > inflate.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      nodeSelector:
        intent: apps
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
          resources:
            requests:
              cpu: 1
              memory: 1.5Gi
EOF
kubectl apply -f inflate.yaml
```

> Este manifiesto también está en [`manifests/inflate.yaml`](../../manifests/inflate.yaml).

> [!IMPORTANT]
> Como Karpenter aprovisiona nodos según los *resource requests* y las restricciones de scheduling, es importante aplicar requests precisos a todas las cargas. Consulta la sección de [confiabilidad](https://aws.github.io/aws-eks-best-practices/) de la guía de buenas prácticas de Amazon EKS.

## Reto

Usa `eks-node-viewer` o `kubectl` para visualizar los cambios y responder:

1. **¿Por qué Karpenter no escaló el clúster tras el despliegue inicial?** → Porque el Deployment arranca con `replicas: 0`, por lo que no hay pods pendientes que disparen el aprovisionamiento.
2. **¿Cómo escalar el Deployment a 1 réplica?** → `kubectl scale deployment inflate --replicas 1`
3. **¿Qué tipo de instancia eligió Karpenter y por qué?** → La instancia que mejor empaqueta (*bin-pack*) la petición de recursos del pod, dentro de las restricciones del NodePool. Verifica con `kubectl get nodes -L node.kubernetes.io/instance-type`.
4. **¿Cuáles son las propiedades y labels de la nueva instancia?** → `kubectl get node <node> -o yaml` o con `-L` para labels de capacidad, zona, arquitectura.
5. **¿Por qué se programó el pod en el nodo del NodePool `custom`?** → Por el `nodeSelector intent: apps`, que coincide con el label del NodePool `custom`.
6. **¿Cómo escalar a 10 réplicas y qué instancias se eligen?** → `kubectl scale deployment inflate --replicas 10`. Karpenter elige instancias más grandes para empaquetar más pods.
7. **¿Cómo escalar a 0 y qué ocurre?** → `kubectl scale deployment inflate --replicas 0`. Karpenter consolida y elimina los nodos vacíos tras `consolidateAfter`.

## Qué aprendimos

- Karpenter escala nodos de forma *group-less*: selecciona qué nodos crear según los pods pendientes y la configuración del NodePool, elige las mejores instancias y las aprovisiona. A diferencia del Cluster Autoscaler, no evalúa primero node groups existentes.
- Karpenter puede escalar desde cero (scale-out) cuando hay pods disponibles y volver a cero (scale-in) cuando no hay cargas.
- Los NodePools definen gobernanza y reglas de aprovisionamiento. Requisitos como `karpenter.sh/capacity-type` (on-demand/spot) o `eks.amazonaws.com/instance-size`.
- Karpenter trae buenas prácticas de capacidad incorporadas y elige entre un amplio rango de tipos de instancia. Es clave **no restringir** demasiado los tipos de instancia al usar Spot (e incluso On-Demand) a gran escala.
- Karpenter usa buenas prácticas de *cordon* y *drain* para terminar nodos, controladas por `.spec.disruption.consolidateAfter`.
- Terminar nodos solo cuando están completamente vacíos (`consolidationPolicy: WhenEmpty`) es ideal para cargas batch. Para microservicios stateless de larga duración, usa `WhenEmptyOrUnderutilized`.

---

⬅️ Anterior: [NodePool personalizado](01-nodepool-personalizado.md) · ➡️ Siguiente: [Consolidación](03-consolidacion.md)
