{{/*
laravel-app.workload — renders a Deployment for any role (web/worker/scheduler).

Call with:
  {{- include "laravel-app.workload" (dict "ctx" . "role" "web") }}

The role name selects the matching values key (.Values.web, .Values.worker, …).
Scheduler is force-pinned to replicas=1 + Recreate strategy regardless of values
so two scheduler pods can never overlap during a rollout.
*/}}
{{- define "laravel-app.workload" -}}
{{- $ctx := .ctx -}}
{{- $role := .role -}}
{{- $cfg := index $ctx.Values $role -}}
{{- $fullname := include "laravel-app.fullname" $ctx -}}
{{- $name := printf "%s-%s" $fullname $role | trunc 63 | trimSuffix "-" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $name }}
  labels:
    {{- include "laravel-app.labels" $ctx | nindent 4 }}
    app.kubernetes.io/component: {{ $role }}
spec:
  revisionHistoryLimit: {{ $ctx.Values.revisionHistoryLimit }}
  {{- if eq $role "scheduler" }}
  replicas: 1
  strategy:
    type: Recreate
  {{- else }}
  {{- if not (and (hasKey $cfg "hpa") $cfg.hpa.enabled) }}
  replicas: {{ $cfg.replicas }}
  {{- end }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "laravel-app.selectorLabels" $ctx | nindent 6 }}
      app.kubernetes.io/component: {{ $role }}
  template:
    metadata:
      labels:
        {{- include "laravel-app.selectorLabels" $ctx | nindent 8 }}
        app.kubernetes.io/component: {{ $role }}
      annotations:
        checksum/config: {{ include (print $ctx.Template.BasePath "/configmap.yaml") $ctx | sha256sum }}
    spec:
      serviceAccountName: {{ include "laravel-app.serviceAccountName" $ctx }}
      automountServiceAccountToken: {{ $ctx.Values.serviceAccount.automountServiceAccountToken }}
      {{- with $ctx.Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml $ctx.Values.podSecurityContext | nindent 8 }}
      terminationGracePeriodSeconds: {{ $cfg.terminationGracePeriodSeconds | default 30 }}
      {{- if $ctx.Values.topologySpread.enabled }}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: {{ $ctx.Values.topologySpread.topologyKey }}
          whenUnsatisfiable: {{ $ctx.Values.topologySpread.whenUnsatisfiable }}
          labelSelector:
            matchLabels:
              {{- include "laravel-app.selectorLabels" $ctx | nindent 14 }}
              app.kubernetes.io/component: {{ $role }}
      {{- end }}
      {{- with $cfg.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $cfg.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $cfg.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      restartPolicy: Always
      containers:
        - name: {{ $role }}
          image: {{ include "laravel-app.image" $ctx }}
          imagePullPolicy: {{ $ctx.Values.image.pullPolicy }}
          {{- with $cfg.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $cfg.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if eq $role "web" }}
          ports:
            - name: http
              containerPort: {{ $cfg.port }}
              protocol: TCP
          {{- end }}
          env:
            - name: CONTAINER_ROLE
              value: {{ $cfg.containerRole | quote }}
            {{- if $ctx.Values.sentry.injectRelease }}
            - name: SENTRY_RELEASE
              value: {{ default $ctx.Chart.AppVersion $ctx.Values.image.tag | quote }}
            {{- end }}
            {{- range $k, $v := $cfg.env }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ $fullname }}-config
            {{- range $ctx.Values.envFromConfigMap }}
            - configMapRef:
                name: {{ .name }}
            {{- end }}
            {{- range $ctx.Values.envFromSecret }}
            - secretRef:
                name: {{ .name }}
            {{- end }}
          {{- with $cfg.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $cfg.readinessProbe }}
          {{- if . }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- with $cfg.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          securityContext:
            {{- toYaml $ctx.Values.containerSecurityContext | nindent 12 }}
          {{- if and (hasKey $cfg "preStop") $cfg.preStop.enabled }}
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep {{ $cfg.preStop.sleepSeconds }}"]
          {{- end }}
{{- end -}}
