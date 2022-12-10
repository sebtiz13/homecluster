{{/*
Create image name that is used in the deployment
*/}}
{{- define "nextcloud.imaginary.image" -}}
{{- printf "%s:%s" .Values.imaginary.image.repository (default "latest" .Values.imaginary.image.tag) -}}
{{- end -}}

{{/*
Build configure command
*/}}
{{- define "nextcloud.configure-command" }}
{{- $commands := list -}}
{{/* Wait nextcloud is installed */}}
{{- $commands = append $commands "(until php occ status | grep -q \"installed: true\"; do sleep 1; done)" }}
{{- range $k, $v := .Values.nextcloudConfig.commands }}
{{- $commands = append $commands (printf "(%s)" $v) }}
{{- end -}}
{{/* Combine list in command */}}
{{- join "; " $commands }}
{{- end -}}
