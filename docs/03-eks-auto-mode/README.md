# 03 · EKS Auto Mode

**EKS Auto Mode** extiende la gestión que AWS hace de los componentes de Kubernetes más allá del propio clúster, permitiendo a AWS configurar y administrar la infraestructura necesaria para la operación fluida de tus cargas de trabajo. Puedes delegar decisiones clave de infraestructura y aprovechar la experiencia de AWS en las operaciones del día a día.

EKS Auto Mode incluye muchas capacidades de Kubernetes como componentes gestionados: autoescalado de cómputo, red de pods y servicios, balanceo de carga de aplicaciones, DNS del clúster, almacenamiento en bloque y soporte de GPU.

En este workshop nos enfocamos en las capacidades de **autoescalado de cómputo**. Para más detalles, consulta el [workshop de EKS Auto Mode](https://catalog.workshops.aws/) y la [documentación](https://docs.aws.amazon.com/eks/latest/userguide/automode.html).

---

## Revisar la configuración de EKS Auto Mode

En EKS Auto Mode, el aprovisionamiento de nodos se apoya en objetos de recurso personalizado (CR) de **Karpenter**, con especificaciones dedicadas para EKS Auto Mode: **NodeClass** y **NodePool**.

- La especificación **NodeClass** define ajustes a nivel de infraestructura que aplican a grupos de nodos: configuración de red, almacenamiento y etiquetado de recursos.
- La especificación **NodePool** permite control granular sobre los recursos de cómputo mediante etiquetas y requisitos: categorías de instancias EC2, configuraciones de CPU, zonas de disponibilidad, arquitecturas (`amd64` y `arm64`) y tipos de capacidad (Spot/On-Demand). También puedes fijar límites de CPU y memoria.

### NodePools gestionados por defecto

Por defecto, EKS Auto Mode aprovisiona dos NodePools gestionados:

| NodePool | Propósito | Notas |
|----------|-----------|-------|
| `general-purpose` | Aplicaciones y servicios desplegados por el usuario | Solo arquitectura `amd64` |
| `system` | Componentes críticos a nivel de sistema para la operación del clúster | Tiene un taint `CriticalAddonsOnly` tolerado por los componentes críticos |

> [!NOTE]
> También puedes crear NodePools personalizados si tienes requisitos distintos de cómputo o configuración (por ejemplo, nodos con GPU).

### Explorar el NodePool general-purpose

Ver las instancias gestionadas que pertenecen al NodePool `general-purpose`:

```bash
kubectl get nodes -l karpenter.sh/nodepool=general-purpose
```

Esto debería devolver un resultado vacío (`No resources found`).

Visualizar la configuración YAML del NodePool:

```bash
kubectl get nodepools general-purpose -o yaml
```

### Explorar el NodePool system

Ver las instancias gestionadas que pertenecen al NodePool `system`:

```bash
kubectl get nodes -l karpenter.sh/nodepool=system
```

La salida debería mostrar dos instancias gestionadas (usadas para los dos pods de metrics-server):

```
NAME                  STATUS   ROLES    AGE   VERSION
i-03bb0e7062caab35d   Ready    <none>   46m   v1.32.5-eks-98436be
i-0eb3739b0ce054016   Ready    <none>   46m   v1.32.5-eks-98436be
```

Visualizar la configuración YAML del NodePool:

```bash
kubectl get nodepools system -o yaml
```

> [!IMPORTANT]
> Estos dos NodePools gestionados no se pueden eliminar ni modificar, pero sí puedes [deshabilitarlos](https://docs.aws.amazon.com/eks/latest/userguide/automode.html).

En la siguiente sección aprenderás los detalles de Karpenter, la solución open-source de gestión del ciclo de vida de nodos que EKS Auto Mode usa para escalar el plano de datos de tus clústeres.

---

⬅️ Anterior: [02 · Visualización del clúster](../02-visualizacion-del-cluster/README.md) · ➡️ Siguiente: [04 · Karpenter](../04-karpenter/README.md)
