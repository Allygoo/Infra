# 🚀 API Gateway - Cheat Sheet

Comandos y flujos más comunes para trabajar con el API Gateway de Allygo.

---

## ⚡ Comandos Rápidos

### Terraform

```powershell
# Inicializar
terraform init

# Ver plan
terraform plan

# Aplicar cambios
terraform apply

# Ver outputs
terraform output

# Destruir todo
terraform destroy
```

---

### Sincronización de Documentación

```powershell
# Sincronizar docs (PowerShell)
.\sync-openapi.ps1

# Sincronizar docs (Python)
python sync-openapi.py
```

---

### Git

```powershell
# Ver estado
git status

# Agregar cambios
git add .

# Commit
git commit -m "Descripción del cambio"

# Subir a GitHub
git push

# Ver últimos commits
git log --oneline -5
```

---

### Testing

```bash
# Health check
curl https://allygo-api-gateway-8xcnswdr.ue.gateway.dev/health

# Services Management
curl https://allygo-api-gateway-8xcnswdr.ue.gateway.dev/api/services-management

# Payments
curl https://allygo-api-gateway-8xcnswdr.ue.gateway.dev/api/payments/health

# Con autenticación (si está habilitada)
curl https://allygo-api-gateway-8xcnswdr.ue.gateway.dev/api/payments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🔄 Flujos Comunes

### 1️⃣ Agregar Nuevo Endpoint

```powershell
# 1. Editar openapi.yaml
# Agregar el path y operación

# 2. Agregar variable en variables.tf (si es necesario)
# variable "new_service_url" { ... }

# 3. Actualizar terraform.tfvars (si es necesario)
# new_service_url = "https://..."

# 4. Aplicar cambios
terraform apply

# 5. Sincronizar documentación
.\sync-openapi.ps1

# 6. Subir a GitHub
git add .
git commit -m "Add new endpoint"
git push
```

---

### 2️⃣ Cambiar URL de Backend

```powershell
# 1. Editar terraform.tfvars
# services_management_service_url = "https://new-url.run.app"

# 2. Aplicar
terraform apply

# 3. Verificar
terraform output api_gateway_url
```

---

### 3️⃣ Actualizar Solo Documentación

```powershell
# 1. Editar openapi.yaml
# Cambiar descripciones, ejemplos, etc.

# 2. Sincronizar (NO terraform apply)
.\sync-openapi.ps1

# 3. Subir
git push
```

---

### 4️⃣ Ver Logs de Peticiones

```bash
# Ver últimos logs
gcloud logging read "resource.type=api AND resource.labels.service=allygo-api-gateway" \
  --limit 50 \
  --format json

# Ver logs en tiempo real
gcloud logging tail "resource.type=api AND resource.labels.service=allygo-api-gateway"
```

---

### 5️⃣ Verificar Estado del Gateway

```bash
# Ver detalles del gateway
gcloud api-gateway gateways describe allygo-api-gateway \
  --location=us-east1 \
  --project=allygo

# Listar todas las APIs
gcloud api-gateway apis list --project=allygo

# Listar configuraciones
gcloud api-gateway api-configs list \
  --api=allygo-api-gateway \
  --project=allygo
```

---

## 📁 Archivos Clave

| Archivo | Propósito | ¿Editable? |
|---------|-----------|------------|
| `main.tf` | Infraestructura Terraform | ✅ Sí |
| `variables.tf` | Definición de variables | ✅ Sí |
| `terraform.tfvars` | Valores de configuración | ✅ Sí |
| `openapi.yaml` | Especificación OpenAPI (Terraform) | ✅ Sí |
| `docs/openapi.yaml` | Especificación OpenAPI (Docs) | ❌ No (auto-generado) |
| `docs/index.html` | Página Swagger UI | ✅ Sí |

---

## 🔑 Variables Importantes

```hcl
# terraform.tfvars

# Proyecto y región
project_id = "allygo"
region     = "us-east1"

# Nombre del gateway
api_gateway_name = "allygo-api-gateway"

# Service Account (existente, no se crea)
# terraform-gcp@allygo.iam.gserviceaccount.com

# URLs de servicios
services_management_service_url = "https://services-management-ms-699512703471.us-east1.run.app"
payments_service_url            = "https://payments-ms-699512703471.us-east1.run.app"
users_service_url               = "https://user-authentication-be-699512703471.us-east1.run.app"
```

---

## 🌐 URLs de Referencia

| Servicio | URL |
|----------|-----|
| **API Gateway** | `https://allygo-api-gateway-8xcnswdr.ue.gateway.dev` |
| **Documentación** | `https://YOUR-USERNAME.github.io/allygo/` |
| **Cloud Console** | https://console.cloud.google.com/api-gateway |
| **GitHub Repo** | (tu repositorio) |

---

## 🛠️ Troubleshooting Rápido

### Error: "backends must be defined"
```powershell
# Verifica que terraform.tfvars tenga las URLs correctas
cat terraform.tfvars
```

### Error: "Service account does not have permission"
```bash
# Dar permisos de invoker
gcloud run services add-iam-policy-binding services-management-ms \
  --member="serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region=us-east1
```

### Error: 502 Bad Gateway
```bash
# Verificar que el servicio Cloud Run esté activo
gcloud run services list --region=us-east1

# Probar el servicio directamente
curl https://services-management-ms-699512703471.us-east1.run.app/health
```

### Documentación no actualiza
```powershell
# Ejecutar sync manualmente
.\sync-openapi.ps1

# Verificar que el archivo docs/openapi.yaml cambió
git diff docs/openapi.yaml

# Subir los cambios
git push
```

---

## 📊 Outputs Útiles

```powershell
# URL del API Gateway
terraform output api_gateway_url

# IP estática (para DNS)
terraform output static_ip

# Service Account
terraform output service_account_email

# Ejemplo de curl
terraform output example_curl_command
```

---

## 🎯 Reglas de Oro

1. **SIEMPRE edita `openapi.yaml` (raíz), NUNCA `docs/openapi.yaml`**
2. **Ejecuta `.\sync-openapi.ps1` después de cambiar `openapi.yaml`**
3. **Haz `terraform apply` antes de sincronizar documentación**
4. **Haz commit de TODO (incluido `docs/openapi.yaml` generado)**
5. **GitHub Actions despliega automáticamente cuando haces push**

---

## 📚 Más Información

- 📖 [README Principal](README.md)
- 🔄 [Flujo de Trabajo Detallado](WORKFLOW.md)
- ☁️ [Cloud Run Integration](CLOUD_RUN.md)
- 🌐 [GitHub Pages Setup](docs/SETUP.md)

---

**Última Actualización:** 2024-01-15
