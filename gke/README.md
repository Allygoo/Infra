# GKE Infrastructure - Allygo Microservices

Infraestructura como código (Terraform) para desplegar un **cluster de Google Kubernetes Engine (GKE)** con Artifact Registry y Kubernetes Ingress para los microservicios de Allygo.

---

## 📋 Descripción General

Esta configuración crea:
- ✅ **GKE Cluster** (zonal en `us-central1-a`)
- ✅ **Node Pool** autoscaling (1-5 nodos e2-medium)
- ✅ **Artifact Registry** para imágenes Docker
- ✅ **Kubernetes Ingress** con Google Cloud Load Balancer
- ✅ **Service Account** para CI/CD (GitHub Actions)
- ✅ **IP estática global** para el Ingress

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│  Internet                                                │
│  https://api.allygo.com                                  │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Google Cloud Load Balancer (Layer 7)                   │
│  IP Estática: 34.XX.XX.XX                               │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│  Kubernetes Ingress Controller                           │
│  - Routing: /api/payments → payments-ms                 │
│  - Routing: /api/users → users-ms                       │
└────────────────────┬─────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│  GKE Cluster     │    │  Artifact        │
│  - Deployments   │    │  Registry        │
│  - Services      │    │  (Docker images) │
│  - Pods          │    │                  │
└──────────────────┘    └──────────────────┘
```

---

## 📁 Estructura de Archivos

```
gke/
├── main.tf                    # Recursos principales (GKE, Ingress, Artifact Registry)
├── variables.tf               # Variables de entrada
├── outputs.tf                 # Outputs (cluster name, IP, comandos kubectl)
├── terraform.tfvars.example  # Ejemplo de configuración
├── .gitignore                # Archivos a ignorar en git
└── README.md                 # Esta documentación
```

---

## 🚀 Configuración Inicial

### 1. Copiar archivo de variables

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

### 2. Editar `terraform.tfvars`

```hcl
# REQUERIDO
project_id = "allygo"

# Opcionales (tienen valores por defecto)
region             = "us-central1"
gke_name           = "allygo-cluster"
artifact_repo      = "microservices-repo-allygo"
api_gateway_domain = "api.allygo.com"
```

### 3. Autenticar con GCP

```powershell
gcloud auth application-default login
```

### 4. Desplegar

```powershell
terraform init
terraform plan
terraform apply
```

---

## 🔧 Componentes Principales

### **GKE Cluster**
- **Tipo:** Zonal (us-central1-a)
- **Node Pool:** e2-medium (2 vCPUs, 4 GB RAM)
- **Autoscaling:** 1-5 nodos
- **Networking:** VPC-native
- **Add-ons:** HTTP Load Balancing, HPA

### **Artifact Registry**
- **Formato:** Docker
- **Ubicación:** us-central1
- **URL:** `us-central1-docker.pkg.dev/allygo/microservices-repo-allygo`

### **Kubernetes Ingress**
- **Controller:** GCE (Google Cloud Load Balancer)
- **IP:** Estática global
- **SSL:** Opcional (Google-managed certificates)

---

## 📦 Después del Despliegue

### 1. Configurar kubectl

```bash
terraform output kubectl_command
# Ejecuta el comando que devuelve
```

O manualmente:
```bash
gcloud container clusters get-credentials allygo-cluster \
  --zone=us-central1-a \
  --project=allygo
```

### 2. Verificar el cluster

```bash
kubectl get nodes
kubectl get namespaces
```

### 3. Obtener IP del Ingress

```powershell
terraform output ingress_ip_address
```

### 4. Configurar DNS

En tu proveedor de DNS:
```
Tipo: A
Nombre: api.allygo.com
Valor: <IP_DEL_OUTPUT>
TTL: 3600
```

---

## 🚢 Desplegar Microservicios

### 1. Build y Push de imágenes

```bash
# Autenticar con Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build
docker build -t us-central1-docker.pkg.dev/allygo/microservices-repo-allygo/payments-ms:latest .

# Push
docker push us-central1-docker.pkg.dev/allygo/microservices-repo-allygo/payments-ms:latest
```

### 2. Aplicar manifests de Kubernetes

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 📊 Outputs Disponibles

```powershell
terraform output                    # Ver todos
terraform output cluster_name       # Nombre del cluster
terraform output ingress_ip_address # IP del Ingress
terraform output kubectl_command    # Comando para conectarse
terraform output artifact_registry_url # URL del registry
```

---

## 🔒 Seguridad

### Service Account para CI/CD

Creado automáticamente con permisos:
- ✅ `roles/artifactregistry.writer` - Push de imágenes
- ✅ `roles/container.developer` - Deploy a GKE

### Network Tags

Los nodos tienen tags para firewall rules:
- `gke-node`
- `allow-health-check`

---

## 💰 Estimación de Costos

| Recurso | Especificación | Costo Mensual (aprox.) |
|---|---|---|
| **GKE Cluster** | Management fee | $74.40 |
| **Nodes (min)** | 1× e2-medium | $24.00 |
| **Nodes (max)** | 5× e2-medium | $120.00 |
| **Load Balancer** | HTTP(S) L7 | $18.00 |
| **Artifact Registry** | Storage + egress | $5-20 |
| **TOTAL (mínimo)** | 1 nodo activo | ~$121/mes |
| **TOTAL (máximo)** | 5 nodos activos | ~$237/mes |

**Nota:** Precios aproximados para región us-central1 (2025).

---

## 🛠️ Comandos Útiles

### Verificar recursos

```bash
# Ver nodos
kubectl get nodes

# Ver pods
kubectl get pods --all-namespaces

# Ver servicios
kubectl get services

# Ver ingress
kubectl get ingress allygo-gateway
kubectl describe ingress allygo-gateway
```

### Logs y debugging

```bash
# Logs de un pod
kubectl logs <pod-name>

# Describir un pod
kubectl describe pod <pod-name>

# Eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Escalar deployments

```bash
# Manual
kubectl scale deployment payments-ms --replicas=3

# Ver HPA
kubectl get hpa
```

---

## 🗑️ Destruir la Infraestructura

```powershell
terraform destroy
```

**⚠️ Advertencia:** Esto eliminará el cluster, los nodos, y todos los recursos desplegados.

---

## 📚 Recursos Adicionales

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

---

## 🔄 Actualizaciones

Para actualizar la infraestructura:

```powershell
# Ver cambios
terraform plan

# Aplicar cambios
terraform apply
```

El lifecycle management del node pool previene updates innecesarios y usa `create_before_destroy` para zero downtime.

---

## 📞 Soporte

Para problemas o preguntas, contacta al equipo de infraestructura de Allygo.
