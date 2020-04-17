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

{{ define "common.metadata.tpl" -}}
name: {{ include "common.fullname" . }}
labels:
  {{- include "common.labels" . | nindent 2 -}}
{{- end -}}

{{- /*
Create a standard metadata header
*/ -}}
{{ define "common.metadata" -}}
{{- include "common.utils.flattenCall" (list "common.utils.merge" . "common.metadata.tpl") -}}
{{- end -}}
