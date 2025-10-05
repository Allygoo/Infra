# 🔄 Flujo de Trabajo - API Gateway

Este documento explica cómo funcionan los dos archivos OpenAPI y cuándo usar cada uno.

---

## 📋 Resumen Rápido

| Archivo | Propósito | Editable | Usado Por |
|---------|-----------|----------|-----------|
| `openapi.yaml` | Configuración Terraform | ✅ SÍ | Terraform, GCP |
| `docs/openapi.yaml` | Documentación pública | ❌ NO | Swagger UI, GitHub Pages |

---

## 🎯 Diagrama del Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                        TÚ EDITAS AQUÍ                           │
│                      openapi.yaml (raíz)                        │
│  Contiene: ${services_management_url}, x-google-backend        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │  terraform apply    │
                  │  Despliega a GCP    │
                  └─────────┬───────────┘
                            │
                            ▼
                  ┌─────────────────────────────┐
                  │  Google Cloud API Gateway   │
                  │  URL: allygo-api-gateway... │
                  └─────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                 SINCRONIZACIÓN A DOCUMENTACIÓN                  │
└─────────────────────────────────────────────────────────────────┘

                            │
                            ▼
            ┌───────────────────────────────┐
            │  .\sync-openapi.ps1  O        │
            │  python sync-openapi.py       │
            └───────────┬───────────────────┘
                        │
                        │ Convierte:
                        │ • ${variable} → ejemplo
                        │ • Quita x-google-backend
                        │ • Agrega tags
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NO EDITES ESTE ARCHIVO                        │
│                 docs/openapi.yaml (auto-generado)               │
│  Contiene: valores estáticos, sin variables Terraform          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │   git push          │
                  └─────────┬───────────┘
                            │
                            ▼
                  ┌─────────────────────┐
                  │  GitHub Actions     │
                  │  (auto-deploy)      │
                  └─────────┬───────────┘
                            │
                            ▼
                  ┌─────────────────────────────┐
                  │     GitHub Pages            │
                  │  username.github.io/allygo  │
                  │  (Swagger UI)               │
                  └─────────────────────────────┘
```

---

## 🔍 Diferencias Entre los Archivos

### **openapi.yaml** (Terraform)

```yaml
swagger: "2.0"
info:
  title: Allygo API Gateway
  version: "1.0.0"
host: ${project_id}-api-gateway-xxxxx.${region}.gateway.dev

paths:
  /api/services-management:
    get:
      summary: List all services
      x-google-backend:
        address: ${services_management_url}
        protocol: h2
        jwt_audience: ${services_management_url}
        deadline: 30.0
```

**Características:**
- ✅ Usa variables de Terraform: `${services_management_url}`
- ✅ Contiene `x-google-backend` (específico de GCP)
- ✅ Valores dinámicos inyectados por `terraform apply`
- ✅ **Este es el archivo que editas**

---

### **docs/openapi.yaml** (Documentación)

```yaml
swagger: "2.0"
info:
  title: Allygo API Gateway
  description: |
    API Gateway para microservicios Allygo.
    Última actualización: 2024-01-15
  version: "1.0.0"
host: allygo-api-gateway-8xcnswdr.ue.gateway.dev

paths:
  /api/services-management:
    get:
      summary: List all services
      tags:
        - Services Management
      produces:
        - application/json
      responses:
        '200':
          description: Lista de servicios
```

**Características:**
- ✅ Valores estáticos sin variables
- ✅ No tiene `x-google-backend`
- ✅ Incluye tags, descripciones extendidas
- ✅ **Auto-generado por scripts de sync**

---

## 🛠️ Casos de Uso

### ✅ Caso 1: Agregar Nuevo Endpoint

**Objetivo:** Agregar ruta `/api/notifications`

```powershell
# 1. Editar openapi.yaml
# Agregar el nuevo path manualmente

# 2. Aplicar a GCP
terraform apply

# 3. Sincronizar documentación
.\sync-openapi.ps1

# 4. Subir cambios
git add .
git commit -m "Add notifications endpoint"
git push
```

**Resultado:**
- ✅ API Gateway actualizado en GCP
- ✅ Documentación en GitHub Pages actualizada

---

### ✅ Caso 2: Cambiar Descripción de Endpoint

**Objetivo:** Mejorar documentación sin cambiar infraestructura

```powershell
# 1. Editar openapi.yaml - solo cambiar "summary" o "description"

# 2. Sincronizar (SIN terraform apply)
.\sync-openapi.ps1

# 3. Subir
git push
```

**Resultado:**
- ⏭️ API Gateway NO cambia
- ✅ Documentación actualizada con nuevas descripciones

---

### ✅ Caso 3: Cambiar URL de Backend

**Objetivo:** Apuntar a nuevo servicio Cloud Run

```powershell
# 1. Editar terraform.tfvars
services_management_service_url = "https://new-url.run.app"

# 2. Aplicar
terraform apply

# 3. Opcional: Sincronizar docs si cambió el ejemplo
.\sync-openapi.ps1
git push
```

**Resultado:**
- ✅ API Gateway apunta al nuevo backend
- ✅ Documentación actualizada con nueva URL

---

## 🤖 Scripts de Sincronización

### PowerShell (`sync-openapi.ps1`)

**Cuándo usar:**
- ✅ Eres usuario de Windows
- ✅ No quieres instalar dependencias
- ✅ Quieres ejecución rápida

**Ejecutar:**
```powershell
.\sync-openapi.ps1
```

---

### Python (`sync-openapi.py`)

**Cuándo usar:**
- ✅ CI/CD (GitHub Actions)
- ✅ Multi-plataforma (Mac, Linux, Windows)
- ✅ Procesamiento avanzado de YAML

**Ejecutar:**
```bash
pip install pyyaml
python sync-openapi.py
```

---

## 🎓 Preguntas Frecuentes

### ❓ ¿Por qué dos archivos OpenAPI?

**Respuesta:** Porque Terraform necesita variables dinámicas (`${var}`) y configuraciones específicas de GCP (`x-google-backend`), mientras que Swagger UI necesita un archivo estático sin estas extensiones.

---

### ❓ ¿Puedo editar `docs/openapi.yaml` directamente?

**Respuesta:** **NO.** Será sobrescrito la próxima vez que ejecutes el script de sync. Siempre edita el `openapi.yaml` de la raíz.

---

### ❓ ¿Qué pasa si olvido sincronizar?

**Respuesta:** La documentación en GitHub Pages quedará desactualizada, pero el API Gateway funcionará correctamente. Recuerda ejecutar `.\sync-openapi.ps1` después de cada cambio en `openapi.yaml`.

---

### ❓ ¿GitHub Actions sincroniza automáticamente?

**Respuesta:** **SÍ**, si el archivo `.github/workflows/deploy-docs.yml` está configurado correctamente. Cada push ejecutará el script de Python antes de desplegar.

---

## 🔗 Archivos Relacionados

- **Configuración Terraform:** `main.tf`, `variables.tf`, `terraform.tfvars`
- **OpenAPI Terraform:** `openapi.yaml` (editable)
- **OpenAPI Documentación:** `docs/openapi.yaml` (auto-generado)
- **Scripts:** `sync-openapi.py`, `sync-openapi.ps1`
- **GitHub Actions:** `.github/workflows/deploy-docs.yml`
- **Documentación:** `docs/index.html`, `docs/README.md`, `docs/SETUP.md`

---

## 📚 Más Información

- [README Principal](README.md)
- [Guía de Cloud Run](CLOUD_RUN.md)
- [Configuración GitHub Pages](docs/SETUP.md)
- [Documentación de OpenAPI](https://swagger.io/specification/v2/)

---

**🎯 Regla de Oro:**

```
Edita openapi.yaml (raíz) → terraform apply → sync-openapi → git push
```

**¡Nunca edites `docs/openapi.yaml` manualmente!**
