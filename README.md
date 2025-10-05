# Allygo Infrastructure

Infraestructura como código (Terraform) para la plataforma de microservicios Allygo en Google Cloud Platform.

---

## 📁 Estructura del Proyecto

```
infra/
├── gke/                      # Google Kubernetes Engine + Kubernetes Ingress
│   ├── main.tf               # GKE cluster, node pools, Artifact Registry
│   ├── variables.tf          # Variables para GKE
│   ├── outputs.tf            # Outputs del cluster
│   ├── terraform.tfvars.example
│   └── README.md             # Documentación de GKE
│
├── api-gateway/              # Google Cloud API Gateway (Nativo)
│   ├── main.tf               # API Gateway, API Config
│   ├── openapi.yaml          # Especificación OpenAPI 2.0
│   ├── variables.tf          # Variables para API Gateway
│   ├── outputs.tf            # URL, IP, comandos
│   ├── terraform.tfvars.example
│   ├── CLOUD_RUN.md         # Guía específica para Cloud Run
│   └── README.md             # Documentación de API Gateway
│
└── cloud-run-payments/       # Ejemplo de microservicio en Cloud Run
    └── ...
```

---

## 🎯 ¿Qué Proyecto Usar?

### **Opción 1: GKE con Kubernetes Ingress** (`/gke`)

**Usa esto si:**
- ✅ Tus microservicios corren en **Kubernetes (GKE)**
- ✅ Prefieres control total sobre la infraestructura
- ✅ Necesitas latencia mínima (todo dentro del cluster)
- ✅ Quieres costo predecible (~$121-237/mes)
- ✅ Ya tienes experiencia con Kubernetes

**Incluye:**
- GKE Cluster (zonal)
- Node Pool autoscaling (1-5 nodos)
- Artifact Registry
- Kubernetes Ingress Controller
- Google Cloud Load Balancer (Layer 7)
- Service Account para CI/CD

**Ir a:** [`/gke/README.md`](gke/README.md)

---

### **Opción 2: API Gateway (Nativo de GCP)** (`/api-gateway`)

**Usa esto si:**
- ✅ Tus microservicios corren en **Cloud Run**
- ✅ Necesitas autenticación avanzada (API Keys, OAuth, JWT)
- ✅ Quieres versionado de API nativo
- ✅ Prefieres managed service (sin administración)
- ✅ Necesitas rate limiting y quotas
- ✅ Tienes backends mixtos (Cloud Run, Cloud Functions, GKE)

**Incluye:**
- API Gateway (managed)
- Especificación OpenAPI 2.0
- JWT authentication para Cloud Run
- Service Account con permisos
- IP estática opcional

**Ir a:** [`/api-gateway/README.md`](api-gateway/README.md)

---

## 📊 Comparación Rápida

| Característica | GKE + Ingress | API Gateway |
|---|---|---|
| **Backend recomendado** | GKE (Pods) | Cloud Run |
| **Gestión** | Self-managed | Fully managed |
| **Autenticación** | Básica (extensiones) | Avanzada (nativa) |
| **Rate Limiting** | Plugins | Nativo |
| **SSL/TLS** | Cert-manager | Automático |
| **Costo base mensual** | ~$121 | $0 (pay-per-use) |
| **Costo por uso** | Incluido | ~$3/millón requests |
| **Versionado API** | Manual | Automático |
| **Latencia** | Baja | Media |
| **Configuración** | HCL (Terraform) | OpenAPI YAML |

---

## 🚀 Inicio Rápido

### **Para GKE:**

```powershell
cd gke
Copy-Item terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
terraform init
terraform apply
```

### **Para API Gateway:**

```powershell
cd api-gateway
Copy-Item terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con URLs de Cloud Run
terraform init
terraform apply
```

---

## 🔑 Requisitos

### **Herramientas necesarias:**
- ✅ Terraform >= 1.0
- ✅ gcloud CLI
- ✅ kubectl (para GKE)
- ✅ Cuenta de GCP con facturación habilitada

### **APIs de GCP a habilitar:**

**Para GKE:**
- `container.googleapis.com` (GKE)
- `artifactregistry.googleapis.com` (Artifact Registry)

**Para API Gateway:**
- `apigateway.googleapis.com` (API Gateway)
- `servicemanagement.googleapis.com` (Service Management)
- `servicecontrol.googleapis.com` (Service Control)
- `run.googleapis.com` (Cloud Run - si lo usas)

---

## 🏗️ Arquitecturas

### **GKE + Ingress:**

```
Internet → Load Balancer → Kubernetes Ingress → Services (ClusterIP) → Pods
```

### **API Gateway:**

```
Internet → API Gateway → Cloud Run Services (JWT auth)
```

---

## 💰 Estimación de Costos

### **GKE (mínimo):**
- GKE management: $74/mes
- 1 nodo e2-medium: $24/mes
- Load Balancer: $18/mes
- **Total: ~$121/mes** (+ uso)

### **API Gateway:**
- Sin costo base: $0/mes
- Requests: $3/millón
- Datos: $0.20/GB
- **Total: ~$5-20/mes** (según uso)

### **Cloud Run (opcional con API Gateway):**
- CPU: $0.00002400/vCPU-segundo
- Memoria: $0.00000250/GiB-segundo
- Requests: $0.40/millón
- **Total: Variable según uso**

---

## 📝 Mejores Prácticas

### **Seguridad:**
1. ✅ Nunca commitear `terraform.tfvars`
2. ✅ Usar service accounts con permisos mínimos
3. ✅ Habilitar SSL/TLS en producción
4. ✅ Usar secrets de Kubernetes/Secret Manager

### **Costos:**
1. ✅ Ajustar autoscaling según carga real
2. ✅ Usar tipos de máquina apropiados
3. ✅ Monitorear uso con Cloud Monitoring
4. ✅ Considerar Committed Use Discounts

### **Despliegue:**
1. ✅ Siempre hacer `terraform plan` antes de `apply`
2. ✅ Usar workspaces de Terraform para entornos (dev/prod)
3. ✅ Mantener el estado de Terraform en GCS (remote backend)
4. ✅ Implementar CI/CD para aplicar cambios

---

## 🔄 Migración entre Arquitecturas

### **De GKE a API Gateway:**

1. Desplegar servicios en Cloud Run
2. Configurar `api-gateway/terraform.tfvars` con URLs de Cloud Run
3. Aplicar API Gateway: `cd api-gateway && terraform apply`
4. Actualizar DNS para apuntar a la nueva URL
5. Destruir GKE (opcional): `cd gke && terraform destroy`

### **De API Gateway a GKE:**

1. Desplegar cluster GKE: `cd gke && terraform apply`
2. Desplegar pods con deployments de Kubernetes
3. Configurar servicios (ClusterIP) e Ingress
4. Actualizar DNS para apuntar a la IP del Ingress
5. Destruir API Gateway (opcional): `cd api-gateway && terraform destroy`

---

## 🛠️ Troubleshooting

### **Errores comunes:**

**Error: "quota exceeded"**
- Solicita aumento de cuota en [GCP Console](https://console.cloud.google.com/iam-admin/quotas)

**Error: "API not enabled"**
- Habilita las APIs necesarias en cada proyecto

**Error: "already exists"**
- Usa `terraform import` o `terraform state rm` y vuelve a aplicar

---

## 📚 Documentación Adicional

- [GKE Documentation](gke/README.md)
- [API Gateway Documentation](api-gateway/README.md)
- [Cloud Run Guide](api-gateway/CLOUD_RUN.md)
- [Copilot Instructions](.github/copilot-instructions.md)

---

## 📞 Soporte

Para problemas o preguntas sobre la infraestructura de Allygo, contacta al equipo de DevOps.

---

## 🎓 Recursos de Aprendizaje

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [API Gateway Documentation](https://cloud.google.com/api-gateway/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
