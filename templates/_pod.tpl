{{/* vim: set filetype=mustache: */}}

{{- define "common.pod-template.tpl" -}}
{{- $top := first . -}}
{{- $values := index . 1 -}}
metadata:
  labels:
    {{- include "common.selectorLabels" $top | nindent 4 }}
spec:
  {{- with $values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 8 }}
  {{- end }}
  serviceAccountName: {{ include "common.serviceAccountName" $top }}
  securityContext:
    {{- toYaml $values.podSecurityContext | nindent 4 }}
  containers:
    - {{- include "common.container" . | nindent 6 }}
  {{- with $values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{- define "common.pod-template" -}}
{{- include "common.utils.merge" (append . "common.pod-template.tpl") -}}
{{- end -}}
