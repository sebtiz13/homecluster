{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "zitadel-sebtiz13.fullname" -}}
{{- if .Values.zitadel.fullnameOverride }}
{{- .Values.zitadel.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.zitadel.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zitadel-sebtiz13.labels" -}}
helm.sh/chart: {{ include "zitadel.chart" . }}
{{ include "zitadel.selectorLabels" . }}
app.kubernetes.io/version: {{ default .Values.zitadel.image.tag .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zitadel-sebtiz13.serviceAccountName" -}}
{{- if .Values.zitadel.serviceAccount.create }}
{{- default (include "zitadel-sebtiz13.fullname" .) .Values.zitadel.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.zitadel.serviceAccount.name }}
{{- end }}
{{- end }}
