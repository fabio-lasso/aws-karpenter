# 02 · Herramientas de visualización del clúster

En este capítulo exploraremos **eks-node-viewer**, que usaremos durante el workshop para visualizar el clúster de Kubernetes en tiempo real.

## eks-node-viewer

[eks-node-viewer](https://github.com/awslabs/eks-node-viewer) es una herramienta para visualizar el uso dinámico de nodos dentro de un clúster. Fue desarrollada originalmente como herramienta interna de AWS para demostrar la consolidación con Karpenter. Muestra los *resource requests* de los pods programados frente a la capacidad asignable del nodo. **No** mide el uso real de recursos de los pods.

Se recomienda usar una terminal nueva para `eks-node-viewer` en una vista dividida. Para lanzarlo, ejecuta lo siguiente en la nueva pestaña de terminal:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool
```

Mostrará una consola interactiva. Puedes mantenerla en ejecución y volver a esta pestaña para ver cómo cambia el clúster con el tiempo, con nuevos nodos apareciendo a medida que avanzas por el workshop.

> [!TIP]
> Si tienes problemas para ver los colores correctamente, abre una terminal nueva y vuelve a ejecutar el comando.

### Variantes útiles

Visualizar nodos por NodePool y zona de disponibilidad:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool,topology.kubernetes.io/zone -node-selector intent=apps -resources cpu,memory
```

Visualizar por NodePool y arquitectura:

```bash
eks-node-viewer -extra-labels karpenter.sh/nodepool,kubernetes.io/arch
```

---

⬅️ Anterior: [01 · Inicio del workshop](../01-inicio-del-workshop/README.md) · ➡️ Siguiente: [03 · EKS Auto Mode](../03-eks-auto-mode/README.md)
