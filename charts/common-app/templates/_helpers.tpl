{{/*
Expand the name of the chart.
*/}}
{{- define "common-app.name" }}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common-app.chart" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common-app.labels" }}
helm.sh/chart: {{ include "common-app.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Sync options
*/}}
{{- define "common-app.syncOptions" }}
{{- if or .options .createLabeledNamespace }}
syncOptions:
  {{- if .options.applyOutOfSyncOnly }}
  - ApplyOutOfSyncOnly=true
  {{- end }}
  {{- if eq ( .options.prunePropagationPolicy | toString ) "foreground" }}
  - PrunePropagationPolicy=foreground
  {{- else if eq ( .options.prunePropagationPolicy | toString ) "background" }}
  - PrunePropagationPolicy=background
  {{- else if eq ( .options.prunePropagationPolicy | toString ) "orphan" }}
  - PrunePropagationPolicy=orphan
  {{- end }}
  {{- if .options.pruneLast }}
  - PruneLast=true
  {{- end }}
  {{- if .options.replace }}
  - Replace=true
  {{- end }}
  {{- if .options.failOnSharedResource }}
  - FailOnSharedResource=true
  {{- end }}
  {{- if .options.respectIgnoreDifferences }}
  - RespectIgnoreDifferences=true
  {{- end }}
  {{- if or .options.createNamespace .createLabeledNamespace }}
  - CreateNamespace=true
  {{- end }}
{{- end }}
{{- end }}

{{/*
Merge apps values
*/}}
{{- define "common-app.appsValues" }}
{{- $values := tpl .Values.appValues . | fromYaml -}}
{{- if .Values.appValuesEnv }}
{{- $appValuesEnv := tpl .Values.appValuesEnv . | fromYaml -}}
{{- $values = deepCopy $values | mustMerge $appValuesEnv  -}}
{{- end }}

{{- toYaml $values }}
{{- end -}}
