# 🏗️ Arquitectura del API Gateway - Allygo

Documentación técnica de la arquitectura del API Gateway y su integración con microservicios.

---

## 📐 Diagrama de Arquitectura Completo

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           USUARIOS / CLIENTES                            │
│  • Aplicación Web (React)                                                │
│  • Aplicación Móvil (iOS/Android)                                        │
│  • Clientes externos via API                                             │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ HTTPS
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         GOOGLE CLOUD API GATEWAY                         │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │  Managed Service (GCP)                                       │        │
│  │  • URL: allygo-api-gateway-8xcnswdr.ue.gateway.dev          │        │
│  │  • IP: 34.107.189.232                                        │        │
│  │  • Región: us-east1                                          │        │
│  │  • TLS/SSL: Automático (Google-managed certificate)         │        │
│  └─────────────────────────────────────────────────────────────┘        │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────┐        │
│  │  Características                                             │        │
│  │  ✓ Routing basado en OpenAPI 2.0                            │        │
│  │  ✓ Autenticación JWT                                         │        │
│  │  ✓ Rate Limiting & Quotas                                    │        │
│  │  ✓ CORS configurado                                          │        │
│  │  ✓ Logging & Monitoring integrado                            │        │
│  │  ✓ Versionado de configuraciones                             │        │
│  └─────────────────────────────────────────────────────────────┘        │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 │ HTTP/2 (h2)
                                 │ JWT Authentication
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  CLOUD RUN       │    │  CLOUD RUN       │    │  CLOUD RUN       │
│  Services        │    │  Payments        │    │  Users           │
│  Management MS   │    │  Management MS   │    │  Authentication  │
├──────────────────┤    ├──────────────────┤    ├──────────────────┤
│ • 14 endpoints   │    │ • 5 endpoints    │    │ • N endpoints    │
│ • Node.js/Python │    │ • Node.js/Python │    │ • Node.js/Python │
│ • Auto-scaling   │    │ • Auto-scaling   │    │ • Auto-scaling   │
│ • Container-based│    │ • Container-based│    │ • Container-based│
└──────────────────┘    └──────────────────┘    └──────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  Bases de Datos        │
                    │  • Cloud SQL           │
                    │  • Firestore           │
                    │  • Cloud Storage       │
                    └────────────────────────┘
```

---

## 🔐 Flujo de Autenticación

```
┌──────────┐                   ┌──────────────┐                 ┌──────────┐
│  Cliente │                   │ API Gateway  │                 │Cloud Run │
└────┬─────┘                   └──────┬───────┘                 └────┬─────┘
     │                                │                              │
     │ 1. Request con JWT             │                              │
     │──────────────────────────────> │                              │
     │                                │                              │
     │                                │ 2. Valida JWT                │
     │                                │    (jwt_audience)            │
     │                                │                              │
     │                                │ 3. Request autenticado       │
     │                                │────────────────────────────> │
     │                                │                              │
     │                                │ 4. Respuesta del servicio    │
     │                                │ <──────────────────────────  │
     │                                │                              │
     │ 5. Respuesta al cliente        │                              │
     │ <───────────────────────────── │                              │
     │                                │                              │
```

**Configuración JWT en OpenAPI:**
```yaml
x-google-backend:
  address: ${services_management_url}
  jwt_audience: ${services_management_url}
  protocol: h2
  deadline: 30.0
```

---

## 🚦 Routing de Endpoints

### Services Management (14 endpoints)

| Método | Path | Descripción | Backend |
|--------|------|-------------|---------|
| GET | `/health` | Health check | services-management-ms |
| POST | `/api/services-management/order` | Crear orden | services-management-ms |
| GET | `/api/services-management/orders` | Listar órdenes | services-management-ms |
| GET | `/api/services-management/orders/worker` | Órdenes por trabajador | services-management-ms |
| PUT | `/api/services-management/orders/payment` | Actualizar pago de orden | services-management-ms |
| GET | `/api/services-management` | Listar servicios | services-management-ms |
| GET | `/api/services-management/by-category` | Servicios por categoría | services-management-ms |
| GET | `/api/services-management/{service_id}/workers` | Trabajadores de servicio | services-management-ms |
| POST | `/api/services-management/payment/pay-order` | Procesar pago | services-management-ms |
| GET | `/api/services-management/categories` | Listar categorías | services-management-ms |
| GET | `/api/services-management/media/worker/{worker_id}/service/{service_id}` | Media de trabajador | services-management-ms |
| PATCH | `/api/services-management/worker/add-service` | Agregar servicio a trabajador | services-management-ms |
| PATCH | `/api/services-management/worker` | Actualizar trabajador | services-management-ms |

### Payments (5 endpoints)

| Método | Path | Descripción | Backend |
|--------|------|-------------|---------|
| GET | `/api/payments/health` | Health check | payments-ms |
| GET | `/api/payments` | Listar pagos | payments-ms |
| POST | `/api/payments` | Crear pago | payments-ms |
| GET | `/api/payments/{payment_id}` | Obtener pago | payments-ms |
| PUT | `/api/payments/{payment_id}` | Actualizar pago | payments-ms |
| DELETE | `/api/payments/{payment_id}` | Eliminar pago | payments-ms |

---

## 📊 Flujo de Tráfico (Request Lifecycle)

```
1. Cliente envía request
   ↓
2. DNS resuelve allygo-api-gateway-8xcnswdr.ue.gateway.dev → 34.107.189.232
   ↓
3. Google Cloud Load Balancer recibe request (HTTPS)
   ↓
4. API Gateway procesa request
   ├─ Verifica autenticación (JWT)
   ├─ Aplica rate limiting
   ├─ Valida contra OpenAPI spec
   └─ Busca ruta en configuración
   ↓
5. Enruta a Cloud Run backend (HTTP/2)
   ├─ Agrega headers de autenticación
   ├─ Timeout configurado (30s)
   └─ Protocolo h2 optimizado
   ↓
6. Cloud Run procesa request
   ├─ Auto-scaling si es necesario
   ├─ Ejecuta lógica de negocio
   └─ Consulta base de datos
   ↓
7. Cloud Run devuelve respuesta
   ↓
8. API Gateway procesa respuesta
   ├─ Aplica transformaciones CORS
   ├─ Registra en Cloud Logging
   └─ Actualiza métricas
   ↓
9. Respuesta enviada al cliente
```

---

## 🔧 Componentes de Infraestructura

### 1. API Gateway (google_api_gateway_api)
```hcl
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = "allygo-api-gateway"
  project  = "allygo"
}
```
**Función:** Contenedor lógico para la API

---

### 2. API Config (google_api_gateway_api_config)
```hcl
resource "google_api_gateway_api_config" "api_config" {
  provider      = google-beta
  api           = google_api_gateway_api.api.api_id
  api_config_id = "config-${timestamp()}"
  
  openapi_documents {
    document {
      path     = "spec.yaml"
      contents = base64encode(templatefile("openapi.yaml", {...}))
    }
  }
}
```
**Función:** Configuración versionada con OpenAPI spec

---

### 3. Gateway (google_api_gateway_gateway)
```hcl
resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  gateway_id = "allygo-api-gateway"
  api_config = google_api_gateway_api_config.api_config.id
  region     = "us-east1"
}
```
**Función:** Endpoint público con IP y dominio

---

## 🔄 Versionado y Deployments

```
┌─────────────────────────────────────────────────────────────┐
│  API Gateway Versioning                                     │
└─────────────────────────────────────────────────────────────┘

API (allygo-api-gateway)
  │
  ├─ Config v1 (2024-01-10 10:00)  [INACTIVA]
  ├─ Config v2 (2024-01-12 14:30)  [INACTIVA]
  └─ Config v3 (2024-01-15 09:15)  [ACTIVA] ← Gateway apunta aquí

Cada terraform apply crea nueva configuración sin afectar la anterior
Rollback disponible cambiando la referencia del Gateway
```

**Ventajas:**
- ✅ Zero-downtime deployments
- ✅ Historial completo de cambios
- ✅ Rollback instantáneo si es necesario
- ✅ A/B testing posible

---

## 🌐 Red y Conectividad

### DNS Resolution
```
Cliente solicita: allygo-api-gateway-8xcnswdr.ue.gateway.dev
  ↓
Google DNS resuelve a: 34.107.189.232
  ↓
Google Cloud Load Balancer recibe tráfico
  ↓
Enruta a API Gateway en us-east1
```

### Protocolo HTTP/2
```yaml
x-google-backend:
  protocol: h2  # HTTP/2 para mejor rendimiento
```

**Beneficios de h2:**
- ✅ Multiplexing (múltiples requests en una conexión)
- ✅ Header compression
- ✅ Server push capabilities
- ✅ Menor latencia

---

## 📈 Observabilidad

### Cloud Logging
```bash
# Ver logs en tiempo real
gcloud logging tail "resource.type=api"

# Buscar errores
gcloud logging read "resource.type=api AND severity>=ERROR" --limit 100
```

### Cloud Monitoring
- **Métricas disponibles:**
  - Request count
  - Latency (p50, p95, p99)
  - Error rate
  - Backend response time
  - Request size / Response size

### Cloud Trace
- Distributed tracing habilitado por defecto
- Ver tiempo por hop (Gateway → Cloud Run → DB)

---

## 💰 Costos Estimados

### API Gateway
```
Componente                  Costo              Detalles
─────────────────────────────────────────────────────────
API Calls                   $3/millón          Primeras 2M gratis/mes
Data Transfer               $0.20/GB           Salida de datos
Service Account             Gratis             -
Cloud Logging (básico)      Gratis             50 GB/mes incluidos
Cloud Monitoring            Gratis             Métricas básicas

Estimado mensual (10M calls, 50GB): ~$35/mes
```

### Comparación con Alternativas

| Solución | Costo Base | Costo Variable | Gestión |
|----------|------------|----------------|---------|
| API Gateway | $0 | $3/M calls + $0.20/GB | Managed |
| Cloud Load Balancer | $18/mes | $0.008/GB | Semi-managed |
| NGINX en VM | $30/mes (VM) | Transferencia | Self-managed |

---

## 🔒 Seguridad

### Capas de Seguridad

1. **Capa de Transporte**
   - ✅ TLS 1.3 forzado
   - ✅ Certificado Google-managed
   - ✅ HTTPS obligatorio

2. **Capa de Autenticación**
   - ✅ JWT validation en API Gateway
   - ✅ Service Account authentication (terraform-gcp@allygo.iam.gserviceaccount.com)
   - ✅ IAM roles (roles/run.invoker)

3. **Capa de Aplicación**
   - ✅ OpenAPI schema validation
   - ✅ CORS configurado
   - ✅ Rate limiting

4. **Capa de Red**
   - ✅ Cloud Armor (opcional, no configurado actualmente)
   - ✅ VPC Service Controls (opcional)

---

## 🎯 Mejores Prácticas Implementadas

### ✅ Configuración
- Uso de variables de Terraform para flexibilidad
- Configuración versionada con OpenAPI
- Documentación automática con Swagger UI

### ✅ Seguridad
- JWT authentication en todos los endpoints
- Service Account con permisos mínimos
- HTTPS obligatorio

### ✅ Rendimiento
- HTTP/2 para comunicación con backends
- Auto-scaling en Cloud Run
- Timeouts configurados (30s)

### ✅ Monitoreo
- Cloud Logging habilitado
- Cloud Monitoring automático
- Distributed tracing

### ✅ DevOps
- Infrastructure as Code (Terraform)
- GitHub Actions para CI/CD de documentación
- Scripts de sincronización automatizados

---

## 📚 Referencias

- **Configuración:** [main.tf](main.tf)
- **OpenAPI Spec:** [openapi.yaml](openapi.yaml)
- **Flujo de Trabajo:** [WORKFLOW.md](WORKFLOW.md)
- **Cheat Sheet:** [CHEATSHEET.md](CHEATSHEET.md)
- **Cloud Run Guide:** [CLOUD_RUN.md](CLOUD_RUN.md)

---

**Última Actualización:** 2024-01-15
**Versión de Arquitectura:** 1.0
**Región:** us-east1
**Proyecto:** allygo
