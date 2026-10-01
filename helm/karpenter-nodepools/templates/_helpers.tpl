{{/*
Nombre completo del NodeClass con prefijo de entorno.
*/}}
{{- define "knp.nodeClassName" -}}
{{- printf "%s-%s" .Values.environment .Values.nodeClass.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nombre completo de un NodePool: <environment>-<poolName>.
Uso: {{ include "knp.nodePoolName" (dict "env" .Values.environment "pool" $pool.name) }}
*/}}
{{- define "knp.nodePoolName" -}}
{{- printf "%s-%s" .env .pool | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes aplicadas a todos los recursos.
*/}}
{{- define "knp.commonLabels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: karpenter-nodepools
environment: {{ .Values.environment }}
{{- end -}}
