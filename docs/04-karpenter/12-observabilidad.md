# 04.12 · Observabilidad de Karpenter

En EKS Auto Mode, Karpenter corre como componente **gestionado del plano de control**. No hay pods, servicios ni namespaces de Karpenter en el plano de datos, y las métricas Prometheus `karpenter_*` **no** se exponen directamente. En su lugar, observamos el comportamiento de Karpenter a través de sus efectos: pods pendientes, latencia de scheduling, rotación de nodos, composición de la flota y estado de los CRD de Karpenter.

Desplegaremos **Prometheus** y **Grafana** para recolectar estas señales y visualizarlas en un dashboard dedicado.

> [!IMPORTANT]
> Aquí usamos Prometheus y Grafana open-source por simplicidad. En producción, considera [Amazon Managed Service for Prometheus (AMP)](https://aws.amazon.com/prometheus/) y [Amazon Managed Grafana (AMG)](https://aws.amazon.com/grafana/).

## Cómo funciona

Como no podemos hacer scrape a Karpenter directamente, combinamos varias fuentes de métricas:

| Fuente | Qué nos dice |
|--------|--------------|
| `kube-state-metrics` (con node labels) | Composición de la flota: Spot vs On-Demand, Graviton vs x86, tipos de instancia, asignación de NodePool |
| `kube-state-metrics` Custom Resource State | Métricas de CRD de Karpenter: conteo de nodos del NodePool, CPU, pods; info de NodeClaim (tipo de capacidad, instancia, arquitectura, zona) |
| `kube-scheduler` (ksh) vía `metrics.eks.amazonaws.com` | Latencia de scheduling, colas de pods pendientes, tasas de intentos, preemption |
| `kube-controller-manager` (kcm) vía `metrics.eks.amazonaws.com` | Salud del controller manager |
| `node-exporter` | Uso de CPU/memoria por nodo y a nivel de clúster |
| `kubelet` | Latencia de arranque de pods y desglose de duración de arranque de nodos |

> [!NOTE]
> Programamos Prometheus y Grafana en el NodePool `system` de EKS Auto Mode mediante `nodeSelector` y una toleration `CriticalAddonsOnly`, para que la pila de monitoreo sobreviva a las disrupciones de nodos.

## Resumen de pasos

> El detalle completo (valores de Helm, PromQL y dashboards) está en el workshop original. Aquí se resume el flujo.

1. **Desplegar Prometheus**: añadir repos Helm, crear namespace `monitoring`, configurar `kube-state-metrics` para exponer node labels de Karpenter y vigilar los CRDs (NodePool, NodeClaim, NodeClass), e instalar con `helm upgrade --install prometheus prometheus-community/prometheus -n monitoring -f prometheus-values.yaml`.
2. **Conceder RBAC** a Prometheus para la API de métricas del plano de control (`metrics.eks.amazonaws.com`) y reiniciar el deployment.
3. **Desplegar Grafana**: cargar el dashboard *Karpenter Impact* como ConfigMap, instalar con Helm exponiendo un `LoadBalancer` (NLB), y recuperar URL y contraseña admin.
4. **Explorar el dashboard** *EKS Auto Mode - Karpenter Impact* con auto-refresh de 5s.
5. **Desplegar NodePool `custom` y cargas de muestra** (On-Demand, Spot, Graviton) para poblar el dashboard.

### Comandos útiles de observación

Conteo total de nodos (PromQL en Grafana → Explore):

```promql
count(kube_node_info)
```

Observar disrupciones:

```bash
kubectl get events -A -w | grep -i disruption
```

Visualizar NodePool y arquitectura en vivo:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool,kubernetes.io/arch
```

## Reto

1. **¿Cómo monitorear la salud y latencia de scheduling?** → Métricas de `ksh` (kube-scheduler): latencia, colas de pods pendientes, tasas de intentos.
2. **¿Cuál es la composición de mi flota (Spot vs On-Demand, Graviton vs x86)?** → Node labels vía `kube-state-metrics`: `karpenter.sh/capacity-type`, `kubernetes.io/arch`, `karpenter.sh/nodepool`, `node.kubernetes.io/instance-type`.

## Limpieza de la pila de monitoreo

```bash
kubectl delete pod load-generator --ignore-not-found
kubectl delete hpa ui --ignore-not-found
kubectl delete deployment ui inflate-spot inflate-efficient --ignore-not-found
kubectl delete service ui --ignore-not-found
helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
rm -f prometheus-values.yaml grafana-values.yaml karpenter-impact.json
```

## Qué aprendimos

- La API de métricas del plano de control (`metrics.eks.amazonaws.com`) expone métricas de `kube-scheduler` (ksh) y `kube-controller-manager` (kcm): latencia de scheduling, colas de pods pendientes y tasas de intentos.
- El *Custom Resource State* de `kube-state-metrics` puede vigilar los CRDs de Karpenter (NodePool, NodeClaim, NodeClass) y generar métricas Prometheus con visibilidad equivalente a las métricas nativas.
- Los node labels expuestos (`karpenter.sh/capacity-type`, `kubernetes.io/arch`, `karpenter.sh/nodepool`, `node.kubernetes.io/instance-type`) dan visibilidad completa de la composición de la flota.

---

⬅️ Anterior: [Debugging con Kiro](11-debugging-con-kiro.md) · ➡️ Volver: [04 · Karpenter](README.md)
