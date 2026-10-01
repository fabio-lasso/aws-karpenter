# 05 · Escalado de aplicación y clúster

## Autoescalado con HPA y Karpenter

En esta sección veremos patrones para escalar automáticamente tanto los nodos worker como los Deployments de aplicaciones. Nos enfocaremos en:

- **Desplegar un microservicio** que genera carga de CPU. Usaremos un servicio web trivial que aproxima π mediante un método de Monte Carlo.
- **Horizontal Pod Autoscaler (HPA)**: escala los pods de un Deployment o ReplicaSet. Es un recurso de la API de Kubernetes y un controlador. El controller manager consulta la utilización de recursos contra las métricas de cada definición de HPA, obtenidas de la *resource metrics API* (métricas por pod) o la *custom metrics API*.
- **Karpenter**: ya lo conoces. Aquí veremos cómo funciona en combinación con HPA.

---

## Configurar HPA

Hasta ahora escalamos réplicas manualmente. Ahora desplegamos el [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) con una regla que escala al alcanzar un umbral de CPU. Al elegir una métrica de escalado, elige una que cambie en proporción con la demanda de tu carga.

> [!TIP]
> HPA es más versátil que escalar solo por CPU/memoria. [KEDA](https://keda.sh/) (Kubernetes Event-driven Autoscaler) trabaja junto al HPA y puede escalar según el número de eventos a procesar (por ejemplo, la longitud de una cola Amazon SQS).

Crea una regla HPA que escala cuando la CPU supera el 50% del recurso asignado al contenedor:

```bash
kubectl autoscale deployment monte-carlo-pi-service --cpu-percent=50 --min=3 --max=10
```

Visualiza el HPA (puede mostrar `<unknown>/50%` durante 1-2 minutos, luego `0%/50%`):

```bash
kubectl get hpa
```

---

## Prueba de estrés del sistema

Para estresar la aplicación usaremos la utilidad [`hey`](https://github.com/rakyll/hey), que genera peticiones en paralelo al `monte-carlo-pi-service`. Esto genera carga en los pods y dispara el HPA.

```bash
URL=$(kubectl get svc monte-carlo-pi-service | tail -n 1 | awk '{ print $4 }')
hey -c 1 -n 1 "http://${URL}/utility/stress/1000000"
```

### Escalar aplicación y clúster

> [!IMPORTANT]
> Antes de la prueba, predice el resultado esperado. Usa `eks-node-viewer` para verificar que los cambios ocurren con el tiempo.

En una terminal:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool
```

En otra terminal, ejecuta la prueba de carga (3000 peticiones, ~1.3s cada una, durante 5 minutos):

```bash
URL=$(kubectl get svc monte-carlo-pi-service | tail -n 1 | awk '{ print $4 }')
hey -c 5 -n 3000 -z 5m "http://${URL}/utility/stress/1000000"
```

### Reto

1. **¿Cómo seguir el estado de la regla HPA?** → `kubectl get hpa` (o `kubectl describe hpa monte-carlo-pi-service`).
2. **¿Y los nodos o pods?** → `kubectl get pods -o wide`, `kubectl get nodes`, y la vista de `eks-node-viewer`.

> [!TIP]
> Consulta el [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/).

Lo esperado: a medida que `hey` genera carga, el HPA escala las réplicas del `monte-carlo-pi-service` (de 3 hasta 10) y, al no caber en los nodos actuales, Karpenter aprovisiona nuevos nodos. Al terminar la prueba, el HPA reduce las réplicas y Karpenter consolida los nodos.

---

⬅️ Anterior: [04 · Karpenter](../04-karpenter/README.md) · ➡️ Siguiente: [06 · Conclusión](../06-conclusion/README.md)
