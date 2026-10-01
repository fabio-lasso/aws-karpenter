# 08 · (Opcional) Recursos y lecturas adicionales

Este capítulo recopila recursos para explorar a tu ritmo.

## Recursos

- [Amazon EKS Auto Mode Best Practices](https://docs.aws.amazon.com/eks/latest/best-practices/automode.html) — buenas prácticas al usar EKS Auto Mode.
- [Karpenter Best Practices](https://aws.github.io/aws-eks-best-practices/karpenter/) — buenas prácticas al usar Karpenter.
- [Karpenter Blueprints](https://github.com/aws-samples/karpenter-blueprints) — escenarios comunes de cargas de trabajo al adoptar Karpenter.
- [How to upgrade Amazon EKS worker nodes with Karpenter Drift](https://aws.amazon.com/blogs/containers/how-to-upgrade-amazon-eks-worker-nodes-with-karpenter-drift/)
- [Documentación oficial de Karpenter](https://karpenter.sh/docs/)
- [Amazon EKS Workshop](https://www.eksworkshop.com/) — workshop base del que deriva este contenido.

## Lógica de batching de Karpenter

La siguiente sección explica la lógica y las variables de temporización que Karpenter usa para aprovisionar pods no programables. Variables de entorno observables en la configuración de Karpenter:

| Variable | Descripción |
|----------|-------------|
| `BATCH_IDLE_DURATION` | Tiempo máximo sin nuevos pods pendientes que, si se excede, cierra la ventana de batching actual. Si los pods llegan más rápido que este tiempo, la ventana se extiende hasta `maxDuration`; si llegan más lento, se agrupan por separado. |
| `BATCH_MAX_DURATION` | Longitud máxima de una ventana de batch. Cuanto más larga, más pods se consideran a la vez para aprovisionamiento, lo que suele resultar en nodos menos numerosos pero más grandes. |

Estas variables determinan cómo Karpenter agrupa (batch) los pods pendientes antes de aprovisionar nodos, en conjunto con la lógica del `kube-scheduler`.

---

⬅️ Anterior: [07 · Limpieza](../07-limpieza/README.md) · 🏠 [Inicio](../../README.md)
