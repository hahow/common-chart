{{/* vim: set filetype=mustache: */}}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "common.metadata.tpl" -}}
{{- $top := first . -}}
name: {{ include "common.fullname" $top }}
labels:
  {{- include "common.labels" $top | nindent 2 -}}
{{- end -}}

{{- /*
Create a standard metadata header
*/ -}}
{{- define "common.metadata" -}}
{{- include "common.utils.merge" (append . "common.metadata.tpl") -}}
{{- end -}}
