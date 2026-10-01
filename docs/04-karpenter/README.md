# 04 · Karpenter

El aprovisionamiento de nodos de EKS Auto Mode se apoya en objetos de [Karpenter](https://karpenter.sh/), con especificaciones dedicadas para [NodeClasses](https://karpenter.sh/docs/concepts/nodeclasses/) y [NodePools](https://karpenter.sh/docs/concepts/nodepools/).

- **NodeClass**: define ajustes a nivel de infraestructura para grupos de nodos (red, almacenamiento, etiquetado de recursos).
- **NodePool**: permite control granular sobre los recursos de cómputo mediante etiquetas y requisitos (categorías de instancias EC2, configuraciones de CPU, zonas de disponibilidad, arquitecturas ARM64/AMD64 y tipos de capacidad Spot/On-Demand). También puedes fijar límites de CPU y memoria.

Karpenter simplifica la infraestructura de Kubernetes proporcionando los nodos adecuados en el momento adecuado. Aprovisiona nodos en respuesta a pods no programables, basándose en la agregación de peticiones de CPU, memoria, volúmenes y otras restricciones de scheduling.

> [!NOTE]
> Con EKS Auto Mode no es necesario instalar manualmente Karpenter: todas estas capacidades están incluidas en la característica de EKS. Las instancias EC2 creadas son [EC2 managed instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managed-instances.html), que delegan el control operativo a EKS Auto Mode.

## Comparación: group-less vs. node groups

Otras soluciones usan el concepto de *node group* como elemento de control que define las características de la capacidad (On-Demand, Spot, GPU, etc.) y controla la escala deseada. En AWS, un node group se corresponde con un [Auto Scaling group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html). Con el tiempo, los clústeres que ejecutan distintos tipos de aplicaciones terminan con una configuración compleja donde los node groups deben definirse por adelantado.

Karpenter adopta un enfoque **group-less** (sin grupos): selecciona qué nodos escalar en función del número de pods pendientes y la configuración del NodePool, decide cómo deberían ser las mejores instancias para la carga y las aprovisiona.

## Subsecciones

| # | Tema | Documento |
|---|------|-----------|
| 1 | Configurar un NodePool personalizado | [`01-nodepool-personalizado.md`](01-nodepool-personalizado.md) |
| 2 | Aprovisionamiento automático de nodos | [`02-aprovisionamiento-automatico.md`](02-aprovisionamiento-automatico.md) |
| 3 | Consolidación | [`03-consolidacion.md`](03-consolidacion.md) |
| 4 | Despliegues en Amazon EC2 Spot | [`04-spot.md`](04-spot.md) |
| 5 | Consolidación Spot-a-Spot | [`05-consolidacion-spot-a-spot.md`](05-consolidacion-spot-a-spot.md) |
| 6 | Múltiples NodePools | [`06-multiples-nodepools.md`](06-multiples-nodepools.md) |
| 7 | Despliegues multiarquitectura (Graviton) | [`07-multiarquitectura.md`](07-multiarquitectura.md) |
| 8 | Uso de NodePools alternativos | [`08-nodepools-alternativos.md`](08-nodepools-alternativos.md) |
| 9 | Presupuestos de disrupción (Disruption Budgets) | [`09-disruption-budgets.md`](09-disruption-budgets.md) |
| 10 | Depuración de Karpenter en Auto Mode | [`10-debugging.md`](10-debugging.md) |
| 11 | Depuración con Kiro (opcional) | [`11-debugging-con-kiro.md`](11-debugging-con-kiro.md) |
| 12 | Observabilidad de Karpenter | [`12-observabilidad.md`](12-observabilidad.md) |

---

⬅️ Anterior: [03 · EKS Auto Mode](../03-eks-auto-mode/README.md) · ➡️ Siguiente: [05 · Escalado](../05-escalado/README.md)
