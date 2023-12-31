{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "config-syncer.name" -}}
{{- default .Chart.Name (index .Values "config-syncer" "nameOverride") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "config-syncer.fullname" -}}
{{- $Values := index .Values "config-syncer" }}
{{- if $Values.fullnameOverride }}
{{- $Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name $Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "config-syncer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "config-syncer.labels" -}}
helm.sh/chart: {{ include "config-syncer.chart" . }}
{{ include "config-syncer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "config-syncer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "config-syncer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "config-syncer.serviceAccountName" -}}
{{- $Values := index .Values "config-syncer" }}
{{- if $Values.serviceAccount.create }}
{{- default (include "config-syncer.fullname" .) $Values.serviceAccount.name }}
{{- else }}
{{- default "default" $Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create image name that is used in the deployment
*/}}
{{- define "config-syncer.image" -}}
{{- $Values := index .Values "config-syncer" }}
{{- if $Values.image.tag }}
{{- printf "%s:%s" $Values.image.repository $Values.image.tag -}}
{{- else }}
{{- printf "%s:%s-%s" $Values.image.repository .Chart.AppVersion "alpine" -}}
{{- end }}
{{- end -}}
