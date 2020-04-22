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



### `common.deployment`

The `common.deployment` template accepts a list of three values:

- the top context
- `$deployment`, a dictionary of values used in the deployment template
- `$autoscaling`, a dictionary of values used in the hpa template
- [optional] the template name of the overrides

It defines a basic `Deployment` with the following settings:

| Value | Description |
| ----- | ----------- |
| `$deployment.replicaCount` | Number of replica. If autoscaling enabled, this field will be ignored |
| `$deployment.imagePullSecrets` | [optional] Name of Secret resource containing private registry credentials |
| `$deployment.podSecurityContext` | [optional] Security options for pod |
| `$deployment.nodeSelector` | [optional] Node labels for pod assignment |
| `$deployment.affinity` | [optional] Expressions for affinity |
| `$deployment.tolerations` | [optional] Toleration labels for pod assignment |
| `$autoscaling.enabled` | [optional] Set this to `true` to enable autoscaling |

Underneath the hood, it uses [`common.container`](#commoncontainer).

By default, the pod template within the deployment defines the labels 

```yaml
app.kubernetes.io/name: {{ template "common.name" }}
app.kubernetes.io/instance: {{ .Release.Name }}
```

as this is also used as the selector. The standard set of labels are not used as some of these can change during upgrades, which causes the replica sets and pods to not correctly match.

Example use:

```yaml
{{- template "common.deployment" (list . .Values .Values.autoscaling) -}}

## The following is the same as above:
# {{- template "common.deployment" (list . .Values .Values.autoscaling "mychart.deployment") -}}
# {{- define "mychart.deployment" -}}
# {{- end -}}
```



### `common.service`

The `common.service` template accepts a list of three values:

- the top context
- `$service`, a dictionary of values used in the service template
- [optional] the template name of the overrides

It creates a basic `Service` resource with the following defaults:

- Service type (ClusterIP, NodePort, LoadBalancer) made configurable by `$service.type`
- Named port `http` configured on port `$service.port`
- Selector set to

  ```yaml
  app.kubernetes.io/name: {{ template "common.name" }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  ```

  to match the default used in the `Deployment` resource

Example template:

```yaml
{{- template "common.service" (list . .Values.service "mychart.mail.service") -}}
{{- define "mychart.mail.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ template "common.fullname" $top }}-mail  # overrides the default name to add a suffix
  labels:                                           # appended to the labels section
    protocol: mail
spec:
  ports:                                            # composes the `ports` section of the service definition.
  - name: smtp
    port: 25
    targetPort: 25
  - name: imaps
    port: 993
    targetPort: 993
  selector:                                         # this is appended to the default selector
    protocol: mail
{{- end }}
---
{{ template "common.service" (list . .Values.service "mychart.web.service") -}}
{{- define "mychart.web.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ template "common.fullname" $top }}-www   # overrides the default name to add a suffix
  labels:                                           # appended to the labels section
    protocol: www
spec:
  ports:                                            # composes the `ports` section of the service definition.
  - name: www
    port: 80
    targetPort: 8080
{{- end -}}
```

The above template defines _two_ services: a web service and a mail service.

The most important part of a service definition is the `ports` object, which defines the ports that this service will listen on. Most of the time, `selector` is computed for you. But you can replace it or add to it.

The output of the example above is:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
    protocol: www
  name: release-name-mychart-www
spec:
  ports:
  - name: www
    port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/name: mychart
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
    protocol: mail
  name: release-name-mychart-mail
spec:
  ports:
  - name: smtp
    port: 25
    targetPort: 25
  - name: imaps
    port: 993
    targetPort: 993
  selector:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/name: mychart
    protocol: mail
  type: ClusterIP
```
