# 04.10 · Depuración de Karpenter en Auto Mode

Con Karpenter gestionado en Auto Mode, aún querrás saber si tus pods no se programan en los nodos correctos (o no se programan en absoluto). Esta sección usa los **Kubernetes Events** y el campo `status` de los objetos NodePool y NodeClass para evaluar tu configuración.

## Revisar eventos de Kubernetes

Si tus pods están en estado `Pending` más tiempo del esperado, empieza por los [Kubernetes Events](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/):

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Revisar el estado de los NodeClaims

Cuando Karpenter inicia el aprovisionamiento, crea un objeto [NodeClaim](https://karpenter.sh/docs/concepts/nodeclaims/) para gestionar el ciclo de vida de los nodos. Revísalos para validar que el proceso está libre de errores.

Busca NodeClaims con `Ready = False`:

```bash
kubectl get nodeclaim
```

Revisa el `status` del NodeClaim específico (incluye detalles del error):

```bash
kubectl get NodeClaim <NodeClaim> -o jsonpath='{.status}' | jq .
```

## Revisar el estado del NodePool

Los NodePools son objetos de Kubernetes; valida problemas vía sus campos `status`. Revisa la sección `resources` (cpu, memoria y datos relacionados):

```bash
kubectl get nodepool general-purpose -o jsonpath='{.status}' | jq .
```

> [!TIP]
> Encuentra técnicas comunes de depuración en la [documentación de Karpenter](https://karpenter.sh/docs/troubleshooting/).

---

⬅️ Anterior: [Disruption Budgets](09-disruption-budgets.md) · ➡️ Siguiente: [Debugging con Kiro](11-debugging-con-kiro.md)
