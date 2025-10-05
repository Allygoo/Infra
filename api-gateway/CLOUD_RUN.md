# Configuración para Cloud Run

Este documento explica las configuraciones específicas para usar API Gateway con **Cloud Run**.

---

## ⚡ Resumen Rápido

**¿Necesito configurar permisos manualmente?**
❌ **NO** - Terraform ya configura `roles/run.invoker` a nivel de proyecto en `main.tf`

**¿Qué hace Terraform automáticamente?**
✅ Habilita APIs necesarias
✅ Configura service account `terraform-gcp`
✅ Da permisos para invocar Cloud Run
✅ Despliega API Gateway con OpenAPI config

**Solo necesitas:**
1. Desplegar tus servicios a Cloud Run (`gcloud run deploy`)
2. Copiar las URLs a `terraform.tfvars`
3. `terraform apply`

---

## 🔑 Configuraciones Clave para Cloud Run

### 1. **JWT Audience Authentication**

Cloud Run requiere autenticación JWT. Cada backend incluye:

```yaml
x-google-backend:
  address: https://payments-ms-xxxxx.a.run.app
  jwt_audience: https://payments-ms-xxxxx.a.run.app  # ← CRÍTICO
  protocol: h2
  deadline: 30.0
```

**¿Por qué?**
- Cloud Run valida que las peticiones vengan de un service account autorizado
- `jwt_audience` debe coincidir con la URL del servicio
- API Gateway automáticamente genera y firma el JWT

---

### 2. **Service Account con Permisos**

El service account `terraform-gcp@allygo.iam.gserviceaccount.com` necesita:

```hcl
# Permiso para invocar Cloud Run (TODOS los servicios del proyecto)
roles/run.invoker

# Permiso para Service Management (API Gateway)
roles/servicemanagement.serviceController
```

✅ **Ya configurado automáticamente** en `main.tf` a nivel de proyecto.

**¿Qué significa "nivel de proyecto"?**
- `terraform-gcp` puede invocar CUALQUIER servicio Cloud Run en el proyecto `allygo`
- No necesitas dar permisos individuales por servicio
- Terraform aplica esto automáticamente con `terraform apply`

---

### 3. **Path Translation**

Para rutas con parámetros (`/api/payments/{id}`), usa:

```yaml
x-google-backend:
  address: https://payments-ms-xxxxx.a.run.app/{payment_id}
  path_translation: APPEND_PATH_TO_ADDRESS  # ← Importante
```

**Opciones:**
- `APPEND_PATH_TO_ADDRESS`: Añade el path completo (recomendado)
- `CONSTANT_ADDRESS`: Ignora parámetros del path

---

### 4. **Timeout Configuration**

Cloud Run tiene límite de 60 segundos por defecto. Configura:

```yaml
x-google-backend:
  deadline: 30.0  # Timeout en segundos (max: 60)
```

---

## 🚀 Pasos para Configurar

### **Paso 1: Desplegar tus servicios a Cloud Run**

```bash
# Ejemplo para payments-ms
gcloud run deploy payments-ms \
  --image us-east1-docker.pkg.dev/allygo/microservices-repo-allygo/payments-ms:latest \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --service-account terraform-gcp@allygo.iam.gserviceaccount.com
```

**⚠️ Importante:** Usa `--no-allow-unauthenticated` para que solo API Gateway pueda invocarlo.

---

### **Paso 2: Obtener las URLs de Cloud Run**

```bash
gcloud run services list --platform managed --region us-east1 --format="table(SERVICE,URL)"
```

**Salida esperada:**
```
SERVICE       URL
payments-ms   https://payments-ms-abc123-ue.a.run.app
users-ms      https://users-ms-def456-ue.a.run.app
orders-ms     https://orders-ms-ghi789-ue.a.run.app
```

---

### **Paso 3: Configurar `terraform.tfvars`**

```hcl
project_id = "allygo"
region     = "us-east1"

# URLs de Cloud Run (copiar del paso anterior)
payments_service_url = "https://payments-ms-abc123-ue.a.run.app"
users_service_url    = "https://users-ms-def456-ue.a.run.app"
orders_service_url   = "https://orders-ms-ghi789-ue.a.run.app"
```

---

### **Paso 4: Verificar permisos del Service Account**

⚠️ **IMPORTANTE:** El permiso `roles/run.invoker` ya está configurado a **nivel de proyecto** en `main.tf`.

**Esto significa que `terraform-gcp` puede invocar TODOS los servicios Cloud Run en el proyecto automáticamente.**

✅ **NO necesitas ejecutar comandos manualmente** - Terraform ya lo configuró.

<details>
<summary>🔒 <b>Opción Alternativa:</b> Permisos a nivel de servicio individual (más seguro)</summary>

Si prefieres dar permisos solo a servicios específicos:

1. **Comenta** el recurso `google_project_iam_member.api_gateway_invoker` en `main.tf`
2. **Ejecuta** estos comandos para cada servicio:

```bash
gcloud run services add-iam-policy-binding payments-ms \
  --region=us-east1 \
  --member="serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com" \
  --role="roles/run.invoker"

gcloud run services add-iam-policy-binding users-ms \
  --region=us-east1 \
  --member="serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com" \
  --role="roles/run.invoker"

gcloud run services add-iam-policy-binding orders-ms \
  --region=us-east1 \
  --member="serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

</details>

---

### **Paso 5: Desplegar API Gateway**

```powershell
cd infra/api-gateway
terraform init
terraform plan
terraform apply
```

Terraform creará:
- ✅ API Gateway con rutas configuradas
- ✅ Permisos `roles/run.invoker` a nivel proyecto (automático)
- ✅ Service account configuration

---

## 🧪 Probar la Configuración

### **1. Obtener URL del API Gateway**

```powershell
terraform output api_gateway_url
```

**Ejemplo:** `https://allygo-api-gateway-xxxxx.uc.gateway.dev`

---

### **2. Probar endpoints**

```bash
# Health check
curl https://allygo-api-gateway-xxxxx.uc.gateway.dev/api/payments/health

# Listar pagos
curl https://allygo-api-gateway-xxxxx.uc.gateway.dev/api/payments

# Obtener un pago
curl https://allygo-api-gateway-xxxxx.uc.gateway.dev/api/payments/123
```

---

## 🔒 Seguridad en Cloud Run

### **Cloud Run Privado (Recomendado)**

Tus servicios de Cloud Run deben ser **privados** (no permitir acceso público):

```bash
gcloud run services update payments-ms \
  --region=us-east1 \
  --no-allow-unauthenticated
```

Solo API Gateway podrá invocarlos gracias al JWT.

---

### **Verificar que está protegido**

```bash
# Esto debe fallar (403 Forbidden)
curl https://payments-ms-abc123-uc.a.run.app/health

# Esto debe funcionar (pasa por API Gateway)
curl https://allygo-api-gateway-xxxxx.uc.gateway.dev/api/payments/health
```

---

## 📊 Diferencias vs GKE

| Aspecto | Cloud Run | GKE (ClusterIP) |
|---|---|---|
| **URL del Backend** | `https://service-xxx.a.run.app` | `http://service.namespace.svc.cluster.local` |
| **Autenticación** | JWT (obligatorio) | No requerida |
| **Protocol** | `https` (h2) | `http` (h2) |
| **jwt_audience** | Requerido | No aplica |
| **Permisos** | `run.invoker` | No requerido |
| **Networking** | Público (con auth) | Privado (VPC) |

---

## ⚠️ Troubleshooting

### **Error: "UNAUTHENTICATED"**

**Causa:** El service account no tiene permiso `run.invoker`.

**Solución 1 (Recomendada):** Verificar que Terraform aplicó el permiso a nivel proyecto:
```bash
# Verificar permisos del service account
gcloud projects get-iam-policy allygo \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com AND bindings.role:roles/run.invoker"
```

Deberías ver:
```
bindings:
- members:
  - serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com
  role: roles/run.invoker
```

**Solución 2 (Si falta el permiso):** Asegúrate de que `main.tf` tiene el recurso:
```hcl
resource "google_project_iam_member" "api_gateway_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${data.google_service_account.terraform_gcp.email}"
}
```

Luego ejecuta `terraform apply`.

**Solución 3 (Granular por servicio):** Si prefieres permisos individuales:
```bash
gcloud run services add-iam-policy-binding payments-ms \
  --member="serviceAccount:terraform-gcp@allygo.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region=us-east1
```

---

### **Error: "DEADLINE_EXCEEDED"**

**Causa:** El backend tardó más de 30 segundos en responder.

**Solución:** Aumenta el `deadline` en `openapi.yaml`:
```yaml
x-google-backend:
  deadline: 60.0  # Máximo permitido
```

---

### **Error: "NOT_FOUND"**

**Causa:** La URL del backend es incorrecta.

**Solución:** Verifica que la URL en `terraform.tfvars` coincide con:
```bash
gcloud run services describe payments-ms \
  --region=us-east1 \
  --format="value(status.url)"
```

---

## 🎯 Ejemplo Completo

### **1. Desplegar Cloud Run Service (payments-ms)**

```bash
# Desplegar el servicio
gcloud run deploy payments-ms \
  --image us-east1-docker.pkg.dev/allygo/microservices-repo-allygo/payments-ms:latest \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated

# Obtener la URL del servicio
URL=$(gcloud run services describe payments-ms --region=us-east1 --format="value(status.url)")
echo "Payments URL: $URL"
# Output: https://payments-ms-abc123-ue.a.run.app
```

---

### **2. Configurar Terraform**

Edita `terraform.tfvars`:
```hcl
project_id = "allygo"
region = "us-east1"

# Pegar la URL obtenida del paso anterior
payments_service_url = "https://payments-ms-abc123-ue.a.run.app"
```

---

### **3. Desplegar API Gateway**

```powershell
cd infra/api-gateway
terraform apply
```

Terraform automáticamente:
- ✅ Configura permisos `roles/run.invoker` a nivel proyecto
- ✅ Crea el API Gateway con configuración OpenAPI
- ✅ Conecta el gateway con tu servicio Cloud Run

---

### **4. Probar**

```bash
# Obtener URL del API Gateway
GATEWAY_URL=$(terraform output -raw api_gateway_url)

# Probar endpoint
curl https://$GATEWAY_URL/api/payments/health
```

---

## 💡 Best Practices

1. **URLs completas:** Siempre usa `https://` en Cloud Run URLs
2. **JWT audience:** Debe coincidir exactamente con la URL del servicio
3. **Privacidad:** Usa `--no-allow-unauthenticated` en Cloud Run (solo API Gateway puede acceder)
4. **Timeouts:** Ajusta `deadline` según la latencia de tu servicio
5. **Monitoring:** Revisa logs en Cloud Console → API Gateway → Logs
6. **Permisos:** Usa permisos a nivel proyecto (ya configurado en `main.tf`) para simplificar
7. **Región consistente:** Usa `us-east1` tanto en Cloud Run como en API Gateway

---

## 📚 Referencias

- [API Gateway with Cloud Run](https://cloud.google.com/api-gateway/docs/authenticate-service-account)
- [Cloud Run Authentication](https://cloud.google.com/run/docs/authenticating/service-to-service)
- [OpenAPI x-google-backend](https://cloud.google.com/endpoints/docs/openapi/openapi-extensions)
