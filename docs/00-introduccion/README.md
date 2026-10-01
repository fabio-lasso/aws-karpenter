# 00 · Introducción

**Ejecución de cargas de trabajo eficientes en cómputo con Karpenter y Amazon EKS Auto Mode**

> [!IMPORTANT]
> Si ejecutas este workshop fuera de un evento oficial de AWS, incurrirás en costos.

## Objetivo

Aprenderás a aprovisionar, gestionar y mantener clústeres de Kubernetes con Amazon Elastic Kubernetes Service (Amazon EKS), escalando de forma óptima mediante **EKS Auto Mode**. En EKS Auto Mode, el aprovisionamiento de nodos se apoya en objetos de **Karpenter**.

Karpenter observa los pods entrantes y lanza instancias Amazon EC2 del tamaño adecuado según los requisitos de las cargas de trabajo. Las decisiones de selección de instancias se basan en la intención y se guían por la especificación de los pods entrantes, incluyendo *resource requests* y las restricciones de scheduling de Kubernetes.

En este workshop se despliega un clúster de Amazon EKS con EKS Auto Mode habilitado. Karpenter aprovisiona una mezcla de instancias **On-Demand** y **Amazon EC2 Spot** para mostrar los beneficios de un autoescalador *group-less* (sin grupos de nodos). Las instancias Spot son capacidad sobrante de AWS que permite optimizar costos mientras se aplican buenas prácticas de escalabilidad y resiliencia.

Este workshop está basado en el [Amazon EKS Workshop](https://www.eksworkshop.com/), ampliando y enfocándose en la creación de clústeres eficientes con Karpenter y buenas prácticas de cómputo eficiente.

## Audiencia objetivo

> [!NOTE]
> No se cubre la introducción a Amazon EKS. Se espera que las personas participantes comprendan Kubernetes, Horizontal Pod Autoscaler (HPA) y Cluster Autoscaler.

## Duración esperada

Aproximadamente **2 horas**.

## Prerrequisitos

- Comprensión básica de Kubernetes.
- (Opcional) Inicio de sesión en Kiro usando login social, AWS Builder ID o AWS IAM Identity Center, con acceso al nivel gratuito (Free tier).

## Estructura del workshop

1. Iniciar el workshop
2. Explorar las herramientas de visualización del clúster
3. EKS Auto Mode
4. Karpenter
5. Escalado de una aplicación y del clúster
6. Conclusión
7. Limpieza
8. (Opcional) Recursos / Lecturas adicionales

---

➡️ Siguiente: [01 · Inicio del workshop](../01-inicio-del-workshop/README.md)
