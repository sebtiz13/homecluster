{{/*
Create image name that is used in the deployment
*/}}
{{- define "nextcloud.imaginary.image" -}}
{{- printf "%s:%s" .Values.imaginary.image.repository (default "latest" .Values.imaginary.image.tag) -}}
{{- end -}}
