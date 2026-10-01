# 04.4 · Despliegues en Amazon EC2 Spot

Las instancias **Amazon EC2 Spot** se crean a partir de capacidad sobrante de AWS, ofreciendo descuentos de hasta el **90%** frente a On-Demand. Por su naturaleza, pueden ser interrumpidas, por lo que la carga de trabajo debe ser: **tolerante a fallos, flexible y stateless**. Las cargas en contenedores suelen ser candidatas ideales por su naturaleza inmutable.

> [!TIP]
> Al usar Spot, sé lo más flexible posible en: tipos de instancia, tamaños, zonas de disponibilidad y, a veces, regiones. La diversidad amplía los *pools* de capacidad sobrante disponibles, reduciendo el riesgo de interrupción.

Karpenter selecciona una lista diversificada de instancias y usa la estrategia de asignación **price-capacity-optimized** para elegir los pools Spot óptimos: minimizar interrupciones manteniendo buen empaquetado de los pods pendientes.

## ¿Cómo funcionan las interrupciones Spot?

Cuando AWS necesita recuperar capacidad para On-Demand (o se agota un pool), envía un **aviso de interrupción Spot** con **2 minutos de antelación** para terminar grácilmente. Un *Spot Instance pool* es un conjunto de instancias EC2 sin usar con el mismo tipo, sistema operativo, zona de disponibilidad y plataforma de red.

Las instancias Spot también soportan **rebalance recommendations**: una señal de que una instancia tiene riesgo elevado de interrupción, dando la oportunidad de reequilibrar cargas proactivamente antes del aviso de 2 minutos.

### Karpenter y las interrupciones Spot

Karpenter gestiona nativamente las notificaciones de interrupción consumiendo eventos de una cola **Amazon SQS** poblada vía **Amazon EventBridge**. Al recibir una notificación, drena grácilmente el nodo interrumpido mientras aprovisiona un nuevo nodo para que los pods se reprogramen rápidamente.

## Crear un Deployment en Spot

El `nodeSelector` incluye `karpenter.sh/capacity-type: spot`, un label que se añade a los nodos aprovisionados en Spot.

```bash
cat <<EOF > inflate-spot.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate-spot
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate-spot
  template:
    metadata:
      labels:
        app: inflate-spot
    spec:
      nodeSelector:
        intent: apps
        karpenter.sh/capacity-type: spot
      containers:
      - image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
        name: inflate-spot
        resources:
          requests:
            cpu: "1"
            memory: 256M
EOF
kubectl apply -f inflate-spot.yaml
```

> Disponible también en [`manifests/inflate-spot.yaml`](../../manifests/inflate-spot.yaml).

> [!IMPORTANT]
> Tu aplicación debe apagarse de forma segura manejando la señal **SIGTERM**. Kubernetes envía SIGTERM al proceso principal (PID 1) de cada contenedor en los pods a desalojar, y tras un período de gracia (30 s por defecto) envía SIGKILL. Puedes ajustarlo con `terminationGracePeriodSeconds` en el spec del pod.

## Reto

1. **Escalar a 2 réplicas Spot** → `kubectl scale deployment inflate-spot --replicas 2`
2. **¿Es eso todo en buenas prácticas de Spot?** → No; además hay que manejar SIGTERM, usar diversidad de instancias, PDBs, y aprovechar las rebalance recommendations.
3. **Escalar a 0**:

```bash
kubectl scale deployment inflate-spot --replicas 0
```

## Qué aprendimos

Cómo aplicar las buenas prácticas de Spot y cómo Karpenter maneja las interrupciones de forma nativa y grácil.

---

⬅️ Anterior: [Consolidación](03-consolidacion.md) · ➡️ Siguiente: [Consolidación Spot-a-Spot](05-consolidacion-spot-a-spot.md)
