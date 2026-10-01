# 01 · Inicio del workshop · Probar el clúster

Interactuarás con **VS Code dentro del navegador**, que te da acceso directo a un clúster de Amazon EKS.

## En un evento guiado por AWS

> [!IMPORTANT]
> Usa estas instrucciones solo si asistes a un evento oficial de AWS (Summit, Loft, re:Invent, etc.). Este workshop crea una cuenta de AWS y varios recursos por ti. Necesitarás el **Participant Hash** del evento y tu correo electrónico para rastrear tu sesión única.

1. En el portal del workshop, lee y acepta los **Términos y Condiciones** y haz clic en **Join event**.
2. Serás llevado a la página de inicio de AWS Workshop Studio, donde accedes a la consola e instrucciones.
3. Accede a la consola de tu cuenta de AWS provisionada mediante el enlace en la barra lateral.
4. Haz clic en **Get started** para abrir la página inicial del workshop.

## Probar el acceso a VS Code Server

1. Abre el **Event dashboard** de Workshop Studio.
2. Desplázate a la sección **Event Outputs**.
3. Copia la **Password** (la necesitarás en el siguiente paso).
4. Haz clic en **VSCodeURL** para abrir Visual Studio Code Server.
5. En el diálogo *Welcome to code-server*, pega la contraseña y haz clic en **Submit**.
6. Verás el IDE de Visual Studio Code.

### Abrir una terminal

Haz clic en el icono de hamburguesa (☰) → **Terminal** → **New Terminal**. Esta es la terminal que usarás durante el workshop.

### Dividir la terminal

Puedes dividir la terminal en 2 para ejecutar comandos `kubectl` en una y otras operaciones en la otra.

### Pegar comandos en la terminal

- **Windows/Linux:** `Shift+V`
- **macOS:** `Cmd+Shift+V`

## Probar el clúster

Valida que EKS Auto Mode ya está habilitado en el clúster:

```bash
aws eks describe-cluster --name karpenter-workshop --query 'cluster.computeConfig.enabled'
```

Consulta los nodos de Kubernetes actualmente aprovisionados:

```bash
kubectl get nodes
```

Deberías ver nodos aprovisionados:

```
NAME                  STATUS   ROLES    AGE   VERSION
i-03bb0e7062caab35d   Ready    <none>   30m   v1.32.5-eks-98436be
i-0eb3739b0ce054016   Ready    <none>   30m   v1.32.5-eks-98436be
```

Consulta los pods actualmente en ejecución:

```bash
kubectl get pods -A
```

El add-on **Metrics Server** ya está instalado en el clúster. Deberías ver sus pods ejecutándose. Es necesario para monitorear el uso de recursos durante el workshop:

```
NAMESPACE     NAME                             READY   STATUS    RESTARTS   AGE
kube-system   metrics-server-5c4c8db9c-dhl4x   1/1     Running   0          37m
kube-system   metrics-server-5c4c8db9c-gcj5q   1/1     Running   0          37m
```

Ya tienes un entorno listo para usar tu clúster de Amazon EKS.

> [!TIP]
> Explora la sección de **Amazon Elastic Kubernetes Service (Amazon EKS)** en la consola de AWS y revisa las propiedades del clúster recién creado.

---

⬅️ Anterior: [00 · Introducción](../00-introduccion/README.md) · ➡️ Siguiente: [02 · Visualización del clúster](../02-visualizacion-del-cluster/README.md)
