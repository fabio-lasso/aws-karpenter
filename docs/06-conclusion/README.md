# 06 · Conclusión

En este workshop aprendiste cómo **EKS Auto Mode** aprovecha **Karpenter** para ofrecer un escalado gestionado y *group-less* que simplifica las operaciones de clústeres de Kubernetes. EKS Auto Mode aplica automáticamente un enfoque *service-first*, aprovisionando capacidad de forma inteligente según los requisitos de la aplicación, sin la sobrecarga de configuración manual. También implementa automáticamente buenas prácticas de cómputo flexible, diversificando los tipos de instancia EC2 y optimizando costo y disponibilidad.

## Qué logramos

- Interactuamos con un clúster EKS Auto Mode con gestión de infraestructura automatizada.
- Exploramos cómo EKS Auto Mode configura y gestiona Karpenter automáticamente para un escalado óptimo, sin configuración manual.
- Aprendimos cómo simplifica la gestión de NodePools con valores por defecto inteligentes, permitiendo personalización vía NodePools `custom`.
- Vimos cómo maneja la selección de AMI y el *bootstrapping* de nodos con mínima configuración.
- Entendimos cómo usa los *well-known labels* de Karpenter para aprovisionar capacidad que cumpla requisitos de arquitectura, tipos de instancia (On-Demand o Spot) y zonas de disponibilidad.
- Aprendimos cómo aplica buenas prácticas de despliegue a gran escala diversificando tipos de instancia y usando estrategias de asignación óptimas, mientras las apps especifican requisitos vía Node Selectors como `kubernetes.io/arch: arm64` o `karpenter.sh/capacity-type: spot`.
- Exploramos cómo configura el *deprovisioning* y la consolidación con valores por defecto inteligentes.
- Experimentamos cómo maneja grácilmente las interrupciones Spot con automatización incorporada.

## Ahorro con Amazon EC2 Spot

Al usar instancias EC2 Spot en el workshop logramos un ahorro significativo:

1. Entra a la página de [EC2 Spot Requests](https://console.aws.amazon.com/ec2/) en la consola.
2. Haz clic en el botón **Savings Summary**.

> [!IMPORTANT]
> Logramos un ahorro significativo frente a los precios On-Demand, de forma controlada y a escala. Usa Karpenter para simplificar tus despliegues y EC2 Spot para tus cargas stateless y flexibles. **¡Ahora, a construir!**

---

⬅️ Anterior: [05 · Escalado](../05-escalado/README.md) · ➡️ Siguiente: [07 · Limpieza](../07-limpieza/README.md)
