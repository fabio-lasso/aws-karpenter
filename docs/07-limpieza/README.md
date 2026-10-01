# 07 · Limpieza

> [!IMPORTANT]
> Si ejecutaste este workshop fuera de un evento oficial de AWS, **debes limpiar los recursos** para evitar costos continuos. En un evento guiado por AWS, la cuenta y sus recursos se destruyen automáticamente al finalizar, por lo que normalmente no necesitas hacer limpieza manual.

> [!NOTE]
> La página oficial de *Cleanup* del workshop no se incluyó en el material de referencia. Esta guía recoge los pasos de limpieza derivados de los recursos creados a lo largo del workshop. Ajusta según tu entorno real.

## 1. Escalar a cero y eliminar los Deployments de prueba

```bash
kubectl scale deployment inflate --replicas 0 --ignore-not-found
kubectl scale deployment inflate-spot --replicas 0 --ignore-not-found
kubectl scale deployment inflate-efficient --replicas 0 --ignore-not-found
kubectl scale deployment inflate-team1 --replicas 0 --ignore-not-found
kubectl scale deployment inflate-multiaz --replicas 0 --ignore-not-found

kubectl delete deployment inflate inflate-spot inflate-efficient inflate-team1 inflate-multiaz --ignore-not-found
```

## 2. Eliminar la aplicación de escalado (HPA)

```bash
kubectl delete hpa monte-carlo-pi-service --ignore-not-found
kubectl delete deployment monte-carlo-pi-service --ignore-not-found
kubectl delete service monte-carlo-pi-service --ignore-not-found
```

## 3. Eliminar la pila de observabilidad (si la desplegaste)

```bash
helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
rm -f prometheus-values.yaml grafana-values.yaml karpenter-impact.json
```

## 4. Eliminar los NodePools y NodeClasses personalizados

```bash
kubectl delete nodepool custom team1 --ignore-not-found
kubectl delete nodeclass custom team1 --ignore-not-found
```

> [!NOTE]
> Los NodePools gestionados `general-purpose` y `system` **no** se pueden eliminar.

## 5. Verificar que no quedan nodos de los NodePools personalizados

```bash
kubectl get nodes -l 'karpenter.sh/nodepool,karpenter.sh/nodepool!=system'
```

Karpenter debería consolidar y eliminar los nodos vacíos tras unos minutos.

## 6. Eliminar la infraestructura base

Si desplegaste el clúster tú mismo (fuera de un evento AWS), elimina la infraestructura con la herramienta que usaste para crearla (por ejemplo, `eksctl delete cluster`, `terraform destroy`, o la pila de CloudFormation correspondiente).

```bash
# Ejemplo con eksctl (ajusta nombre y región):
# eksctl delete cluster --name karpenter-workshop --region <region>
```

> [!TIP]
> Confirma en la consola de AWS que se eliminaron las instancias EC2, los balanceadores de carga (NLB creados por Grafana) y cualquier recurso asociado para evitar costos residuales.

---

⬅️ Anterior: [06 · Conclusión](../06-conclusion/README.md) · ➡️ Siguiente: [08 · Recursos](../08-recursos/README.md)
