{{/* vim: set filetype=mustache: */}}

{{- /*
Merge one or more YAML templates and output the result.
This takes an list of values:
- the first item is the top context
- the rest items are template names of the templates, the former one will override the latter.
*/ -}}
{{- define "common.utils.merge" -}}
{{- $top := first . -}}
{{- $dest := dict -}}
{{- range (rest .) -}}
  {{- $src := fromYaml (include . $top) | default (dict) -}}
  {{- $dest = merge $dest $src -}}
{{- end -}}
{{- toYaml $dest -}}
{{- end -}}

{{- /*
Flatten list of arguments before rendering the given template.
This takes an list of values:
- the first item is the template name to be rendered
- the second item is either an list of arguments or a single argument
- the rest items are the appended arguments
*/ -}}
{{- define "common.utils.flattenCall" -}}
{{- $tpl := first . -}}
{{- $args := index . 1 -}}
{{- if not (typeIs "[]interface {}" $args) -}}
  {{- $args = list $args -}}
{{- end -}}
{{- $args = concat $args (slice . 2) -}}
{{- include $tpl $args -}}
{{- end -}}
