## 1.2.4 (2026-03-04)

Update and parametrize OpenBao image.

## 1.2.3 (2026-02-05)

Fixed multiple agent secret creation.

## 1.2.2 (2026-01-23)

Added placeholders for Minio in EDC secrets.

## 1.2.1 (2025-12-19)

Further cleanup in secrets.

## 1.2.0 (2025-12-17)

Changes for release 3.0.x of agents.

## 1.1.2 (2025-12-04)

Moved the initialisation part to another repository, only the configuration is left here.

## 1.1.1 (2025-11-26)

Switch kubectl image from Bitnami to Alpine.
Fix issue with creating secrets with empty value.
Stop overwriting Kafka users secret - allows adding custom users through OpenBao.
Fix sync issue that required deletion of init job.

## 1.1.0 (2025-11-12)

Add ServiceAccount with role and rolebinding.
Extend permissions for SecretEngine used by Infrastructure components.
Extend infrastructure-fe secret.

## 1.0.0 (2025-10-07)

Initial commit. 

