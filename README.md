# Common: The Helm Helper Chart

This chart was originally forked from [`incubator/common`](https://github.com/helm/charts/tree/master/incubator/common), which is designed to make it easier for you to build and maintain Helm charts.

It provides utilities that reflect best practices of Kubernetes chart development, making it faster for you to write charts.



## Contents

- [Installation](#installation)
- [Resource Kinds](#resource-kinds)
  * [`common.configMap`](#commonconfigmap)
  * [`common.cronJob`](#commoncronjob)
  * [`common.deployment`](#commondeployment)
  * [`common.hpa`](#commonhpa)
  * [`common.ingress`](#commoningress)
  * [`common.pdb`](#commonpdb)
  * [`common.secret`](#commonsecret)
  * [`common.service`](#commonservice)
  * [`common.serviceAccount`](#commonserviceaccount)
  * [`common.serviceMonitor`](#commonservicemonitor)
  * [`common.serviceMonitor.secret`](#commonservicemonitorsecret)
- [Partial Objects](#partial-objects)
  * [`common.chart`](#commonchart)
  * [`common.container`](#commoncontainer)
  * [`common.fullname`](#commonfullname)
  * [`common.labels`](#commonlabels)
  * [`common.metadata`](#commonmetadata)
  * [`common.name`](#commonname)
  * [`common.pod.template`](#commonpodtemplate)
  * [`common.selectorLabels`](#commonselectorlabels)
  * [`common.serviceAccountName`](#commonserviceaccountname)



## Installation

To use the library chart, `common` should be listed in `dependencies` field in your `Chart.yaml`:

```yaml
dependencies:
  - name: common
    version: 0.3.0
    repository: https://hahow-helm-charts.storage.googleapis.com/
```

Once you have defined dependencies, you should run the following command to download this chart into your `charts/` directory:

```shell
$ helm dependency update
```



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

Note that the [`common.service`](#commonservice) template defines three parameters:

- The root context (usually `.`)
- A dictionary of values which are used in the template
- A optional template name containing the service definition overrides

A limitation of the Go template library is that a template can only take a single argument. The `list` function is used to workaround this by constructing a list or array of arguments that is passed to the template.

The [`common.service`](#commonservice) template is responsible for rendering the templates with the root context and merging any overrides. As you can see, this makes it very easy to create a basic `Service` resource without having to copy around the standard metadata and labels.

Each implemented base resource is described in greater detail below.



### `common.configMap`

The `common.configMap` template accepts a list of two values:

- `$top`, the top context
- [optional] the template name of the overrides

It creates an empty `ConfigMap` resource that you can override with your configuration.

Example use:

```yaml
{{- include "common.configMap" (list . "mychart.configMap") -}}
{{- define "mychart.configMap" -}}
data:
  zeus: cat
  athena: cat
  julius: cat
  one: |-
    {{ .Files.Get "file1.txt" }}
{{- end -}}
```

Output:

```yaml
apiVersion: v1
data:
  athena: cat
  julius: cat
  one: This is a file.
  zeus: cat
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
```



### `common.cronJob`

The `common.cronJob` template accepts a list of five values:

- `$top`, the top context
- `$cronJob`, a dictionary of values used in the cronjob template
- `$pod`, a dictionary of values used in the pod template
- `$serviceAccount`, a dictionary of values used in the service account template
- [optional] the template name of the overrides

It defines a basic `CronJob` with the following defaults:

- Labels of `JobTemplate` are defined with [`common.selectorLabels`](#commonselectorlabels) as this is also used as the selector.
- Restart policy of pod is set to `OnFailure`

In addition, it uses the following configuration from the `$cronJob`:

| Value | Description |
| ----- | ----------- |
| `$cronJob.schedule` | Schedule for the cronjob |
| `$cronJob.concurrencyPolicy` | [optional] `Allow\|Forbid\|Replace` concurrent jobs |
| `$cronJob.failedJobsHistoryLimit` | [optional] Specify the number of failed jobs to keep |
| `$cronJob.successfulJobsHistoryLimit` | [optional] Specify the number of completed jobs to keep |

Underneath the hood, it invokes [`common.pod.template`](#commonpodtemplate) template with `$pod` to populate the `PodTemplate`.

Example use:

```yaml
{{- include "common.cronJob" (list . .Values.cronJob .Values .Values.serviceAccount) -}}

## The following is the same as above:
# {{- include "common.cronJob" (list . .Values.cronJob .Values .Values.serviceAccount "mychart.cronJob") -}}
# {{- define "mychart.cronJob" -}}
# {{- end -}}
```




### `common.deployment`

The `common.deployment` template accepts a list of five values:

- `$top`, the top context
- `$deployment`, a dictionary of values used in the deployment template
- `$autoscaling`, a dictionary of values used in the hpa template
- `$serviceAccount`, a dictionary of values used in the service account template
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

Underneath the hood, it invokes [`common.pod.template`](#commonpodtemplate) template with `$deployment` to populate the `PodTemplate`.

Example use:

```yaml
{{- include "common.deployment" (list . .Values .Values.autoscaling .Values.serviceAccount) -}}

## The following is the same as above:
# {{- include "common.deployment" (list . .Values .Values.autoscaling .Values.serviceAccount "mychart.deployment") -}}
# {{- define "mychart.deployment" -}}
# {{- end -}}
```



### `common.hpa`

The `common.hpa` template accepts a list of three values:

- `$top`, the top context
- `$autoscaling`, a dictionary of values used in the hpa template
- [optional] the template name of the overrides

It creates a basic `HorizontalPodAutoscaler` resource with the following defaults:

- The name of scaled target is set with [`common.fullname`](#commonfullname)

An example values file that can be used to configure the `HorizontalPodAutoscaler` resource is:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 5
  cpuUtilizationPercentage: 50
  memoryUtilizationPercentage: 90
```

Example use:

```yaml
{{- include "common.hpa" (list . .Values.autoscaling) -}}

## The following is the same as above:
# {{- include "common.hpa" (list . .Values.autoscaling "mychart.hpa") -}}
# {{- define "mychart.hpa" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
spec:
  maxReplicas: 5
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 50
        type: Utilization
    type: Resource
  - resource:
      name: memory
      target:
        averageUtilization: 90
        type: Utilization
    type: Resource
  minReplicas: 3
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: release-name-mychart
```



### `common.ingress`

The `common.ingress` template accepts a list of four values:

- `$top`, the top context
- `$ingress`, a dictionary of values used in the ingress template
- `$service`, a dictionary of values used in the service template
- [optional] the template name of the overrides

It is designed to give you a well-defined `Ingress` resource, that can be configured using `$ingress`. An example values file that can be used to configure the `Ingress` resource is:

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  hosts:
  - host: chart-example.local
    paths:
    - /path/to/somewhere
  tls:
  - secretName: chart-example-tls
    hosts:
    - chart-example.local
service:
  type: ClusterIP
  port: 80
```

Example use:

```yaml
{{- include "common.ingress" (list . .Values.ingress .Values.service) -}}

## The following is the same as above:
# {{- include "common.ingress" (list . .Values.ingress .Values.service "mychart.ingress") -}}
# {{- define "mychart.ingress" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
spec:
  rules:
  - host: "chart-example.local"
    http:
      paths:
      - backend:
          serviceName: release-name-mychart
          servicePort: 80
        path: /path/to/somewhere
  tls:
  - hosts:
    - "chart-example.local"
    secretName: chart-example-tls
```



### `common.pdb`

The `common.pdb` template accepts a list of five values:

- `$top`, the top context
- `$pdb`, a dictionary of values used in the hpa template
- `$deployment`, a dictionary of values used in the deployment template
- `$autoscaling`, a dictionary of values used in the hpa template
- [optional] the template name of the overrides

It creates a basic `PodDisruptionBudget` resource with the following defaults:

- Selector is set with [`common.selectorLabels`](#commonselectorlabels) to match the default used in the `Pod` resource

An example values file that can be used to configure the `PodDisruptionBudget` resource is:

```yaml
podDisruptionBudget:
  ## You can specify only one of maxUnavailable and minAvailable in a single PodDisruptionBudget
  minAvailable: 2
  # maxUnavailable: 1
```

Example use:

```yaml
{{- include "common.pdb" (list . .Values.podDisruptionBudget .Values .Values.autoscaling) -}}

## The following is the same as above:
# {{- include "common.pdb" (list . .Values.podDisruptionBudget .Values .Values.autoscaling "mychart.pdb") -}}
# {{- define "mychart.pdb" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: mychart
```



### `common.secret`

The `common.secret` template accepts a list of two values:

- `$top`, the top context
- [optional] the template name of the overrides

It creates an empty `Secret` resource that you can override with your secrets.

Example use:

```yaml
{{- include "common.secret" (list . "mychart.secret") -}}
{{- define "mychart.secret" -}}
data:
  zeus: {{ print "cat" | b64enc }}
  athena: {{ print "cat" | b64enc }}
  julius: {{ print "cat" | b64enc }}
  one: |-
    {{ .Files.Get "file1.txt" | b64enc }}
{{- end -}}
```

Output:

```yaml
apiVersion: v1
data:
  athena: Y2F0
  julius: Y2F0
  one: VGhpcyBpcyBhIGZpbGUuCg==
  zeus: Y2F0
kind: Secret
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
type: Opaque
```



### `common.service`

The `common.service` template accepts a list of three values:

- `$top`, the top context
- `$service`, a dictionary of values used in the service template
- [optional] the template name of the overrides

It creates a basic `Service` resource with the following defaults:

- Service type (ClusterIP, NodePort, LoadBalancer) made configurable by `$service.type`
- Named port `http` configured on port `$service.port`
- Selector set with [`common.selectorLabels`](#commonselectorlabels) to match the default used in the `Deployment` resource

Example template:

```yaml
{{- include "common.service" (list . .Values.service "mychart.mail.service") -}}
{{- define "mychart.mail.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ include "common.fullname" $top }}-mail # overrides the default name to add a suffix
  labels:                                         # appended to the labels section
    protocol: mail
spec:
  ports:                                          # composes the `ports` section of the service definition.
  - name: smtp
    port: 25
    targetPort: 25
  - name: imaps
    port: 993
    targetPort: 993
  selector:                                       # this is appended to the default selector
    protocol: mail
{{- end }}
---
{{ include "common.service" (list . .Values.service "mychart.web.service") -}}
{{- define "mychart.web.service" -}}
{{- $top := first . -}}
metadata:
  name: {{ include "common.fullname" $top }}-www  # overrides the default name to add a suffix
  labels:                                         # appended to the labels section
    protocol: www
spec:
  ports:                                          # composes the `ports` section of the service definition.
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



### `common.serviceAccount`

The `common.serviceAccount` template accepts a list of three values:

- `$top`, the top context
- `$serviceAccount`, a dictionary of values used in the service account template
- [optional] the template name of the overrides

It creates a basic `ServiceAccount` resource with the following defaults:

- The name is set with [`common.serviceAccountName`](#commonserviceaccountname)
- Lays out the annotations using `$serviceAccount.annotations`

An example values file that can be used to configure the `ServiceAccount` resource is:

```yaml
serviceAccount:
  create: true
  annotations: {}
  name:
```

Example use:

```yaml
{{- include "common.serviceAccount" (list . .Values.serviceAccount) -}}

## The following is the same as above:
# {{- include "common.serviceAccount" (list . .Values.serviceAccount "mychart.serviceAccount") -}}
# {{- define "mychart.serviceAccount" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
```



### `common.serviceMonitor`

The `common.serviceMonitor` template accepts a list of three values:

- `$top`, the top context
- `$serviceMonitor`, a dictionary of values used in the service account template
- [optional] the template name of the overrides

It creates a basic `ServiceMonitor` resource with the following defaults:

- Namespace selector is set to the release namespace
- Selector is set with [`common.selectorLabels`](#commonselectorlabels) to match the default used in the `Service` resource

An example values file that can be used to configure the `ServiceMonitor` resource is:

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  port: 80
  path: /path/to/metrics
  interval: 30s
  scrapeTimeout: 30s
  basicAuth:
    enabled: true
    username: administrator
    password: password
```

Example use:

```yaml
{{- include "common.serviceMonitor" (list . .Values.serviceMonitor) -}}

## The following is the same as above:
# {{- include "common.serviceMonitor" (list . .Values.serviceMonitor "mychart.serviceMonitor") -}}
# {{- define "mychart.serviceMonitor" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
  namespace: monitoring
spec:
  endpoints:
  - basicAuth:
      password:
        key: password
        name: release-name-mychart
      username:
        key: username
        name: release-name-mychart
    interval: 30s
    path: /path/to/metrics
    port: 80
    scrapeTimeout: 30s
  namespaceSelector:
    matchNames:
    - default
  selector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: mychart
```



### `common.serviceMonitor.secret`

The `common.serviceMonitor.secret` template accepts a list of three values:

- `$top`, the top context
- `$serviceMonitor`, a dictionary of values used in the service account template
- [optional] the template name of the overrides

It creates a `Secret` resource contains the BasicAuth information for the `ServiceMonitor`.

An example `values.yaml` for your `ServiceMonitor` could look like:

```yaml
serviceMonitor:
  basicAuth:
    enabled: true
    username: administrator
    password: password
```

Example use:

```yaml
{{- include "common.serviceMonitor.secret" (list . .Values.serviceMonitor) -}}

## The following is the same as above:
# {{- include "common.serviceMonitor.secret" (list . .Values.serviceMonitor "mychart.serviceMonitor.secret") -}}
# {{- define "mychart.serviceMonitor.secret" -}}
# {{- end -}}
```

Output:

```yaml
apiVersion: v1
data:
  password: cGFzc3dvcmQ=
  username: YWRtaW5pc3RyYXRvcg==
kind: Secret
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
  namespace: monitoring
type: Opaque
```



## Partial Objects

When writing Kubernetes resources, you may find the following helpers useful to construct parts of the spec.



### `common.chart`

The `common.chart` helper prints the chart name and version, escaped to be legal in a Kubernetes label field.

Example template:

```yaml
helm.sh/chart: {{ include "common.chart" . }}
```

For the chart `foo` with version `1.2.3-beta.55+1234`, this will render:

```yaml
helm.sh/chart: foo-1.2.3-beta.55_1234
```

(Note that `+` is an illegal character in label values)



### `common.container`

The `common.container` template accepts a list of three values:

- `$top`, the top context
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

The above example creates a `Deployment` resource which makes use of the `common.container` template to populate the `PodSpec`'s container list. The usage of this template is similar to the other resources, you must define and reference a template that contains overrides for the container object.

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



### `common.fullname`

The `common.fullname` template generates a name suitable for the `name:` field in Kubernetes metadata. It is used like this:

```yaml
name: {{ include "common.fullname" . }}
```

This prints the value of `{{ .Release.Name }}-{{ .Chart.Name }}` by default, but can be overridden with `.Values. fullnameOverride`:

```yaml
fullnameOverride: some-name
```

Example output:

```yaml
---
# with the values above
name: some-name

---
# the default, for release "release-name" and chart "mychart"
name: release-name-mychart
```

Output of this function is truncated at 63 characters, which is the maximum length of name.



### `common.labels`

`common.selectorLabels` prints the standard set of labels.

Example usage:

```
{{ include "common.labels" . }}
```

Example output:

```yaml
app.kubernetes.io/instance: release-name
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/name: mychart
app.kubernetes.io/version: 1.16.0
helm.sh/chart: mychart-0.1.0
```



### `common.metadata`

The `common.metadata` helper generates value for the `metadata:` section of a Kubernetes resource.

This takes a list of two values:

- `$top`, the top context
- [optional] the template name of the overrides

It generates standard labels and a name field.

Example template:

```yaml
metadata:
  {{- include "common.metadata" (list .) | nindent 2 }}

## The following is the same as above:
# metadata:
#   {{- include "common.metadata" (list . "mychart.metadata") | nindent 2 }}
# {{- define "mychart.metadata" -}}
# {{- end -}}
```

Example output:

```yaml
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mychart
    app.kubernetes.io/version: 1.16.0
    helm.sh/chart: mychart-0.1.0
  name: release-name-mychart
```

Most of the common templates that define a resource type (e.g. `common.configMap` or `common.cronJob`) use this to generate the metadata, which means they inherit the same `labels` and `name` fields.



### `common.name`

The `common.name` template generates a name suitable for the `app.kubernetes.io/name` label. It is used like this:

```yaml
app.kubernetes.io/name: {{ include "common.name" . }}
```

This prints the value of `{{ .Chart.Name }}` by default, but can be overridden with `.Values.nameOverride`:

```yaml
nameOverride: some-name
```

Example output:

```yaml
---
# with the values above
app.kubernetes.io/name: some-name

---
# the default, for chart "mychart"
app.kubernetes.io/name: mychart
```

Output of this function is truncated at 63 characters, which is the maximum length of name.


### `common.pod.template`

The `common.pod.template` template accepts a list of four values:

- `$top`, the top context
- `$pod`, a dictionary of values used in the container template
- `$serviceAccount`, a dictionary of values used in the service account template
- [optional] the template name of the overrides

It creates a basic `PodTemplate` spec to be used within a `Deployment` or `CronJob`. It holds the following defaults:

- Labels are defined with [`common.selectorLabels`](#commonselectorlabels) as this is also used as the selector.
- Service account name is set with [`common.serviceAccountName`](#commonserviceaccountname)

It also uses the following configuration from the `$pod`:

| Value | Description |
| ----- | ----------- |
| `$pod.imagePullSecrets` | Names of secrets containing private registry credentials |
| `$pod.podSecurityContext` | Security options |
| `$pod.nodeSelector ` | Node labels for pod assignment |
| `$pod.affinity ` | Expressions for affinity |
| `$pod.tolerations ` | Toleration labels for pod assignment |

Underneath the hood, it invokes [`common.container`](#commoncontainer) template with `$pod` to populate the `PodSpec`'s container list.



### `common.selectorLabels`

`common.selectorLabels` prints the standard set of selector labels.

Example usage:

```
{{ include "common.selectorLabels" . }}
```

Example output:

```yaml
app.kubernetes.io/instance: release-name
app.kubernetes.io/name: mychart
```



### `common.serviceAccountName`

The `common.serviceAccountName` template accepts a list of two values:

- `$top`, the top context
- `$serviceAccount`, a dictionary of values used in the service account template

It generates a name suitable for the `serviceAccountName` field of a `Pod` resource.

Example usage:

```
serviceAccountName: {{ include "common.serviceAccountName" . .Values.serviceAccount }}
```

The following values can influence the output:

```yaml
serviceAccount:
  create: true
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name: some-name
```

Example output:

```yaml
---
# with the values above
serviceAccountName: some-name

---
# if serviceAccount.name is not set, the value will be the same as "common.fullname"
serviceAccountName: release-name-mychart

---
# if serviceAccount.create is false, the value will be "default"
serviceAccountName: default
```
