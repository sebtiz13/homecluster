{{/*
Environment is production
*/}}
{{- define "is-production" }}
{{- if ne .Values.environment "production" -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}

{{/*
Annotation for redirect to https
*/}}
{{- define "ingress.annotations.httpsRedirect" -}}
traefik.ingress.kubernetes.io/router.middlewares: traefik-redirect-https@kubernetescrd
traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
{{- end}}

{{/*
TLS Secret name
*/}}
{{- define "ingress.tls.secretName" -}}
{{ .Values.baseDomain | replace "." "-" }}-tls
{{- end}}
