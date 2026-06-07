{{/*
Expand the name of the chart.
*/}}
{{- define "laravel-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name. Truncated to 63 chars (DNS label limit).
*/}}
{{- define "laravel-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Resource name for a specific role: <fullname>-<role> (e.g. budgetbunny-web).
*/}}
{{- define "laravel-app.roleName" -}}
{{- $fullname := include "laravel-app.fullname" .ctx -}}
{{- printf "%s-%s" $fullname .role | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels shared by all resources.
*/}}
{{- define "laravel-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "laravel-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels (must NOT include version — selectors are immutable).
*/}}
{{- define "laravel-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "laravel-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Image reference for the main app image.
*/}}
{{- define "laravel-app.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}

{{/*
Image reference for the frontend image.
*/}}
{{- define "laravel-app.frontendImage" -}}
{{- $tag := default .Chart.AppVersion .Values.frontend.image.tag -}}
{{- printf "%s:%s" .Values.frontend.image.repository $tag -}}
{{- end -}}

{{/*
ServiceAccount name to use.
*/}}
{{- define "laravel-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "laravel-app.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
