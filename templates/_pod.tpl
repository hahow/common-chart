{{/* vim: set filetype=mustache: */}}

{{- define "common.pod.template.tpl" -}}
{{- $top := first . -}}
{{- $pod := index . 1 -}}
metadata:
  labels:
    {{- include "common.selectorLabels" $top | nindent 4 }}
spec:
  {{- with $pod.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "common.serviceAccountName" $top }}
  securityContext:
    {{- toYaml $pod.podSecurityContext | nindent 4 }}
  containers:
    - {{- include "common.container" . | nindent 6 }}
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
{{- end -}}

{{- define "common.pod.template" -}}
{{- include "common.utils.merge" (append . "common.pod.template.tpl") -}}
{{- end -}}
