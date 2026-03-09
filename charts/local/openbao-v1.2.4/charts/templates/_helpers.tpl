{{- define "redpanda.password" -}}
{{- if not (get .Values "redpandaGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "redpandaGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "redpandaGeneratedPassword" -}}
{{- end -}}

{{- define "pgadmin.password" -}}
{{- if not (get .Values "pgadminGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "pgadminGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "pgadminGeneratedPassword" -}}
{{- end -}}

{{- define "rediscommander.password" -}}
{{- if not (get .Values "redisCommanderGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "redisCommanderGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "redisCommanderGeneratedPassword" -}}
{{- end -}}

{{- define "redis.password" -}}
{{- if not (get .Values "redisGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "redisGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "redisGeneratedPassword" -}}
{{- end -}}

{{- define "redpandakafkauser.password" -}}
{{- if not (get .Values "redpandaKafkaGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "redpandaKafkaGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "redpandaKafkaGeneratedPassword" -}}
{{- end -}}

{{- define "notificationkafkauser.password" -}}
{{- if not (get .Values "notificationKafkaGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "notificationKafkaGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "notificationKafkaGeneratedPassword" -}}
{{- end -}}

{{- define "mailpitui.password" -}}
{{- if not (get .Values "mailpituiGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "mailpituiGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "mailpituiGeneratedPassword" -}}
{{- end -}}

{{- define "mailpitsmtp.password" -}}
{{- if not (get .Values "mailpitsmtpGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "mailpitsmtpGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "mailpitsmtpGeneratedPassword" -}}
{{- end -}}

{{- define "icmskafkauser.password" -}}
{{- if not (get .Values "icmsKafkaGeneratedPassword") -}}
{{- $password := randAlphaNum 16 | nospace -}}
{{- $_ := set .Values "icmsKafkaGeneratedPassword" $password -}}
{{- end -}}
{{- get .Values "icmsKafkaGeneratedPassword" -}}
{{- end -}}