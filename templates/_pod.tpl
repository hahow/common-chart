{{/* vim: set filetype=mustache: */}}

{{- define "common.pod.template.tpl" -}}
{{- $top := first . }}
{{- $pod := index . 1 }}
{{- $serviceAccount := index . 2 }}
metadata:
  {{- with $pod.podAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- include "common.selectorLabels" $top | nindent 4 }}
  {{- with $pod.podLabels }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with $pod.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "common.serviceAccountName" (list $top $serviceAccount) }}
  securityContext:
    {{- toYaml $pod.podSecurityContext | nindent 4 }}
  containers:
  - {{- include "common.container" (list $top $pod) | nindent 4 }}
  {{- with $pod.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pod.priorityClassName }}
  priorityClassName: {{ . }}
  {{- end }}
{{- end }}

{{- define "common.pod.template" -}}
{{- include "common.utils.merge" (append . "common.pod.template.tpl") }}
{{- end }}
