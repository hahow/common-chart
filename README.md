# Common: The Helm Helper Chart

This chart was originally forked from [`incubator/common`](https://github.com/helm/charts/tree/master/incubator/common), which is designed to make it easier for you to build and maintain Helm charts.

It provides utilities that reflect best practices of Kubernetes chart development, making it faster for you to write charts.



## Resource Kinds

Kubernetes defines a variety of resource kinds, from `Secret` to `StatefulSet`. We define some of the most common kinds in a way that lets you easily work with them.

The resource kind templates are designed to make it much faster for you to define _basic_ versions of these resources. They allow you to extend and modify just what you need, without having to copy around lots of boilerplate.

To make use of these templates you must define a template that will extend the base template (though it can be empty). The name of this template is then passed to the base template, for example:

```yaml
{{- include "common.service" (list . .Values.service "mychart.service") -}}
{{- define "mychart.service" -}}
## Define overrides for your Service resource here, e.g.
# metadata:
#   labels:
#     custom: label
# spec:
#   ports:
#   - port: 8080
#     targetPort: http
#     protocol: TCP
#     name: http
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
app.kubernetes.io/name: {{ include "common.name" }}
app.kubernetes.io/instance: {{ .Release.Name }}
```

as this is also used as the selector. The standard set of labels are not used as some of these can change during upgrades, which causes the replica sets and pods to not correctly match.

Example use:

```yaml
{{- include "common.deployment" (list . .Values .Values.autoscaling) -}}

## The following is the same as above:
# {{- include "common.deployment" (list . .Values .Values.autoscaling "mychart.deployment") -}}
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
  app.kubernetes.io/name: {{ include "common.name" }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  ```
  to match the default used in the `Deployment` resource

Example template:

```yaml
{{- include "common.service" (list . .Values.service "mychart.mail.service") -}}
{{- define "mychart.mail.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ include "common.fullname" $top }}-mail  # overrides the default name to add a suffix
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
{{ include "common.service" (list . .Values.service "mychart.web.service") -}}
{{- define "mychart.web.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ include "common.fullname" $top }}-www   # overrides the default name to add a suffix
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



## Partial Objects

When writing Kubernetes resources, you may find the following helpers useful to construct parts of the spec.



### `common.container`

The `common.container` template accepts a list of three values:

- the top context
- `$container`, a dictionary of values used in the container template
- [optional] the template name of the overrides

It creates a basic `Container` spec to be used within a `Deployment` or `CronJob`. It holds the following defaults:

- The name is set to the chart name
- Uses `$container.image` to describe the image to run, with the following spec:
  ```yaml
  image:
    repository: nginx
    tag: stable
    pullPolicy: IfNotPresent
  ```
- Lays out the security options using `$container.securityContext`
- Lays out the compute resources using `$container.resources`

Example use:

```yaml
{{- include "common.deployment" (list . .Values .Values.autoscaling "mychart.deployment") -}}
{{- define "mychart.deployment" -}}
## Define overrides for your Deployment resource here, e.g.
spec:
  template:
    spec:
      containers:
      - {{- include "common.container" (append . "mychart.deployment.container") | nindent 8 }}
{{- end -}}
{{- define "mychart.deployment.container" -}}
## Define overrides for your Container here, e.g.
ports:
- name: http
  containerPort: 80
  protocol: TCP
livenessProbe:
  httpGet:
    path: /
    port: http
readinessProbe:
  httpGet:
    path: /
    port: http
{{- end -}}
```

The above example creates a `Deployment` resource which makes use of the `common.container` template to populate the PodSpec's container list. The usage of this template is similar to the other resources, you must define and reference a template that contains overrides for the container object.

The most important part of a container definition is the image you want to run. As mentioned above, this is derived from `$container.image` by default. It is a best practice to define the image, tag and pull policy in your charts' values as this makes it easy for an operator to change the image registry, or use a specific tag or version. Another example of configuration that should be exposed to chart operators is the container's required compute resources, as this is also very specific to an operators environment. An example `values.yaml` for your chart could look like:

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: stable
  pullPolicy: IfNotPresent
securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

The output of running the above values through the earlier template is:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: mychart
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: release-name
        app.kubernetes.io/name: mychart
    spec:
      containers:
      - image: nginx:stable
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /
            port: http
        name: mychart
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /
            port: http
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 128Mi
        securityContext:
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
      serviceAccountName: release-name-mychart
```
