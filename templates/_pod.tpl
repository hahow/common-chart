{{/* vim: set filetype=mustache: */}}

{{- define "common.pod-template.tpl" -}}
metadata:
  labels:
    {{- include "common.selectorLabels" . | nindent 4 }}
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 8 }}
  {{- end }}
  serviceAccountName: {{ include "common.serviceAccountName" . }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  containers:
    - {{- include "common.container" . | nindent 6 }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{- define "common.pod-template" -}}
{{- include "common.utils.flattenCall" (list "common.utils.merge" . "common.pod-template.tpl") -}}
{{- end -}}
