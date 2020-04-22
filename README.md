# Common: The Helm Helper Chart

This chart was originally forked from [`incubator/common`](https://github.com/helm/charts/tree/master/incubator/common), which is designed to make it easier for you to build and maintain Helm charts.

It provides utilities that reflect best practices of Kubernetes chart development, making it faster for you to write charts.



## Resource Kinds

Kubernetes defines a variety of resource kinds, from `Secret` to `StatefulSet`. We define some of the most common kinds in a way that lets you easily work with them.

The resource kind templates are designed to make it much faster for you to define _basic_ versions of these resources. They allow you to extend and modify just what you need, without having to copy around lots of boilerplate.

To make use of these templates you must define a template that will extend the base template (though it can be empty). The name of this template is then passed to the base template, for example:

```yaml
{{- template "common.service" (list . .Values.service "mychart.service") -}}
{{- define "mychart.service" -}}
## Define overrides for your Service resource here, e.g.
# metadata:
#   labels:
#     custom: label
# spec:
#   ports:
#     - port: 8080
#       targetPort: http
#       protocol: TCP
#       name: http
{{- end -}}
```

Note that the `common.service` template defines three parameters:

- The root context (usually `.`)
- A dictionary of values which are used in the template
- A optional template name containing the service definition overrides

A limitation of the Go template library is that a template can only take a single argument. The `list` function is used to workaround this by constructing a list or array of arguments that is passed to the template.

The `common.service` template is responsible for rendering the templates with the root context and merging any overrides. As you can see, this makes it very easy to create a basic `Service` resource without having to copy around the standard metadata and labels.

Each implemented base resource is described in greater detail below.