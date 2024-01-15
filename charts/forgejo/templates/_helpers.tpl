{{/*
Docker Image Registry Secret Names evaluating values as templates
*/}}
{{- define "gitea.actions.images.pullSecrets" -}}
{{- $pullSecrets := .Values.forgejo.imagePullSecrets -}}
{{- range .Values.forgejo.global.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets (dict "name" .) -}}
{{- end -}}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{ toYaml $pullSecrets }}
{{- end }}
{{- end -}}


{{/*
Create image name and tag used by the actions runner.
*/}}
{{- define "gitea.actions.image" -}}
{{- $registry := .Values.actions.runner.image.registry | default (.Values.forgejo.global.imageRegistry | default .Values.forgejo.image.registry) -}}
{{- $name := .Values.actions.runner.image.repository -}}
{{- $tag := .Values.actions.runner.image.tag -}}
{{- $rootless := ternary "-rootless" "" (or .Values.forgejo.image.rootless .Values.actions.runner.image.rootless) -}}
{{- if $registry -}}
  {{- printf "%s/%s:%s%s" $registry $name $tag $rootless -}}
{{- else -}}
  {{- printf "%s:%s%s" $name $tag $rootless -}}
{{- end -}}
{{- end -}}

{{/*
Actions runner labels
*/}}
{{- define "gitea.actions.runner.labels" -}}
helm.sh/chart: {{ include "gitea.chart" . }}
app: actions-runner
{{ include "gitea.actions.runner.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.actions.runner.image.tag | quote }}
version: {{ .Values.actions.runner.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Actions runner selector labels
*/}}
{{- define "gitea.actions.runner.selectorLabels" -}}
app.kubernetes.io/name: actions-runner
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
