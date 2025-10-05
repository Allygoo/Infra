# 📖 Índice de Documentación - API Gateway Allygo

Guía de navegación para toda la documentación del proyecto.

---

## 🎯 Inicio Rápido

### Para Usuarios Nuevos
1. **Leer primero:** [README.md](README.md) - Descripción general
2. **Ver comandos:** [CHEATSHEET.md](CHEATSHEET.md) - Comandos rápidos
3. **Configurar:** Seguir pasos en [Quick Start](README.md#-configuración-inicial)

### Para Desarrolladores
1. **Entender arquitectura:** [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Flujo de trabajo:** [WORKFLOW.md](WORKFLOW.md)
3. **Integración Cloud Run:** [CLOUD_RUN.md](CLOUD_RUN.md)

### Para DevOps/SRE
1. **Infraestructura:** [main.tf](main.tf), [variables.tf](variables.tf)
2. **Monitoreo:** Ver sección en [ARCHITECTURE.md](ARCHITECTURE.md#-observabilidad)
3. **Troubleshooting:** [CHEATSHEET.md](CHEATSHEET.md#️-troubleshooting-rápido)

---

## 📚 Guía de Documentos

| Documento | Descripción | Cuándo Leer |
|-----------|-------------|-------------|
| **[README.md](README.md)** | Descripción general del proyecto | Primer contacto con el proyecto |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Arquitectura técnica detallada | Entender cómo funciona todo |
| **[WORKFLOW.md](WORKFLOW.md)** | Flujo de trabajo con OpenAPI | Antes de editar archivos |
| **[CHEATSHEET.md](CHEATSHEET.md)** | Comandos y tareas comunes | Referencia diaria |
| **[CLOUD_RUN.md](CLOUD_RUN.md)** | Integración con Cloud Run | Configurar nuevos servicios |
| **[docs/SETUP.md](docs/SETUP.md)** | Configuración GitHub Pages | Publicar documentación |
| **[docs/README.md](docs/README.md)** | README de documentación | Mantener el sitio web |

---

## 🗂️ Estructura del Proyecto

```
api-gateway/
│
├── 📄 Documentación
│   ├── README.md              ← Empieza aquí
│   ├── INDEX.md               ← Este archivo
│   ├── ARCHITECTURE.md        ← Arquitectura técnica
│   ├── WORKFLOW.md            ← Flujo de trabajo
│   ├── CHEATSHEET.md          ← Comandos rápidos
│   └── CLOUD_RUN.md           ← Guía Cloud Run
│
├── ⚙️ Terraform
│   ├── main.tf                ← Recursos principales
│   ├── variables.tf           ← Definición de variables
│   ├── outputs.tf             ← Outputs
│   ├── terraform.tfvars       ← Tu configuración (git-ignored)
│   └── terraform.tfvars.example
│
├── 📋 OpenAPI
│   ├── openapi.yaml           ← EDITABLE: Spec con variables Terraform
│   └── docs/openapi.yaml      ← AUTO-GENERADO: Spec para documentación
│
├── 🔄 Scripts
│   ├── sync-openapi.py        ← Sincronización Python
│   └── sync-openapi.ps1       ← Sincronización PowerShell
│
└── 🌐 Documentación Web (GitHub Pages)
    └── docs/
        ├── index.html         ← Página Swagger UI
        ├── openapi.yaml       ← Spec estático (auto-generado)
        ├── README.md          ← README del sitio
        └── SETUP.md           ← Guía de configuración
```

---

## 🎓 Rutas de Aprendizaje

### 🌱 Nivel 1: Básico (Primeros Pasos)

**Objetivo:** Desplegar el API Gateway por primera vez

1. **Leer:** [README.md](README.md) completo
2. **Configurar:** 
   - Copiar `terraform.tfvars.example` a `terraform.tfvars`
   - Editar con tus valores
3. **Ejecutar:**
   ```powershell
   terraform init
   terraform apply
   ```
4. **Verificar:** Probar endpoints con curl
5. **Documentar:** Ver [CHEATSHEET.md](CHEATSHEET.md) para comandos útiles

**Duración:** ~30 minutos  
**Prerrequisitos:** Cuenta GCP, Terraform instalado

---

### 🌿 Nivel 2: Intermedio (Modificar Configuración)

**Objetivo:** Agregar nuevos endpoints y servicios

1. **Leer:** [WORKFLOW.md](WORKFLOW.md) - Entender el flujo
2. **Estudiar:** [openapi.yaml](openapi.yaml) - Estructura actual
3. **Modificar:** Agregar nuevo endpoint siguiendo ejemplos
4. **Aplicar:** `terraform apply`
5. **Sincronizar:** `.\sync-openapi.ps1`
6. **Validar:** Probar nuevo endpoint

**Duración:** ~1 hora  
**Prerrequisitos:** Nivel 1 completado, conocer OpenAPI

---

### 🌳 Nivel 3: Avanzado (Arquitectura y Optimización)

**Objetivo:** Entender arquitectura completa y optimizar

1. **Leer:** [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitectura detallada
2. **Estudiar:** 
   - Flujo de autenticación
   - Request lifecycle
   - Costos y optimización
3. **Configurar:** Monitoreo avanzado, alertas
4. **Optimizar:** Rate limiting, caching
5. **Documentar:** Publicar en GitHub Pages ([docs/SETUP.md](docs/SETUP.md))

**Duración:** ~3 horas  
**Prerrequisitos:** Niveles 1-2, conocer GCP

---

## 🔍 Búsqueda Rápida por Tema

### Terraform
- **Recursos:** [main.tf](main.tf)
- **Variables:** [variables.tf](variables.tf)
- **Outputs:** [outputs.tf](outputs.tf)
- **Comandos:** [CHEATSHEET.md](CHEATSHEET.md#-comandos-rápidos)

### OpenAPI
- **Especificación:** [openapi.yaml](openapi.yaml)
- **Flujo de trabajo:** [WORKFLOW.md](WORKFLOW.md)
- **Agregar endpoints:** [WORKFLOW.md](WORKFLOW.md#️-casos-de-uso)

### Cloud Run
- **Integración:** [CLOUD_RUN.md](CLOUD_RUN.md)
- **Permisos:** [CLOUD_RUN.md](CLOUD_RUN.md) (sección IAM)
- **URLs de servicios:** [terraform.tfvars](terraform.tfvars)

### Documentación
- **GitHub Pages:** [docs/SETUP.md](docs/SETUP.md)
- **Swagger UI:** [docs/index.html](docs/index.html)
- **Sincronización:** [WORKFLOW.md](WORKFLOW.md#-scripts-de-sincronización)

### Troubleshooting
- **Errores comunes:** [CHEATSHEET.md](CHEATSHEET.md#️-troubleshooting-rápido)
- **Logs:** [ARCHITECTURE.md](ARCHITECTURE.md#-observabilidad)
- **Debugging:** [README.md](README.md#-troubleshooting)

---

## 🎯 Casos de Uso Comunes

### "Quiero agregar un nuevo endpoint"
1. **Lee:** [WORKFLOW.md - Caso 1](WORKFLOW.md#-caso-1-agregar-nuevo-endpoint)
2. **Sigue pasos:** En [README.md - Personalizar Rutas](README.md#-personalizar-rutas-openapi)
3. **Referencia:** [CHEATSHEET.md - Agregar Endpoint](CHEATSHEET.md#1️⃣-agregar-nuevo-endpoint)

### "Quiero cambiar la URL de un servicio"
1. **Lee:** [WORKFLOW.md - Caso 3](WORKFLOW.md#-caso-3-cambiar-url-de-backend)
2. **Edita:** `terraform.tfvars`
3. **Aplica:** `terraform apply`

### "Quiero publicar la documentación"
1. **Lee:** [docs/SETUP.md](docs/SETUP.md)
2. **Ejecuta:** Sincronización con `.\sync-openapi.ps1`
3. **Sube:** `git push` y habilita GitHub Pages

### "Tengo un error 502 Bad Gateway"
1. **Ve a:** [CHEATSHEET.md - Troubleshooting](CHEATSHEET.md#error-502-bad-gateway)
2. **Verifica:** Servicios Cloud Run activos
3. **Revisa:** Logs con comandos en [ARCHITECTURE.md](ARCHITECTURE.md#cloud-logging)

### "Quiero entender cómo funciona la autenticación"
1. **Lee:** [ARCHITECTURE.md - Autenticación](ARCHITECTURE.md#-flujo-de-autenticación)
2. **Revisa:** Configuración en [openapi.yaml](openapi.yaml)
3. **Configura:** Según [CLOUD_RUN.md](CLOUD_RUN.md)

---

## 📞 Soporte y Contribución

### Reportar Problemas
1. Revisar [CHEATSHEET.md - Troubleshooting](CHEATSHEET.md#️-troubleshooting-rápido)
2. Revisar logs: `gcloud logging tail "resource.type=api"`
3. Contactar equipo de infraestructura

### Contribuir
1. Leer [WORKFLOW.md](WORKFLOW.md) completo
2. Seguir convenciones de código
3. Actualizar documentación relevante
4. Ejecutar `.\sync-openapi.ps1` antes de commit

---

## 🔗 Enlaces Externos

- **Google Cloud Console:** https://console.cloud.google.com/api-gateway
- **API Gateway Docs:** https://cloud.google.com/api-gateway/docs
- **OpenAPI Spec:** https://swagger.io/specification/v2/
- **Terraform GCP Provider:** https://registry.terraform.io/providers/hashicorp/google/latest/docs

---

## 📊 Estado del Proyecto

| Componente | Estado | Versión | Notas |
|------------|--------|---------|-------|
| API Gateway | 🟢 Activo | 1.0 | Producción en us-east1 |
| Documentación | 🟢 Completa | 1.0 | GitHub Pages lista |
| Terraform | 🟢 Funcional | 1.0 | google-beta provider |
| Cloud Run | 🟢 Integrado | - | 3 microservicios |
| Monitoreo | 🟢 Habilitado | - | Cloud Logging/Monitoring |

---

## 🗺️ Roadmap

### ✅ Completado
- API Gateway desplegado
- 19 endpoints configurados
- Documentación completa
- GitHub Pages setup
- Automatización de sincronización

### 🚧 En Progreso
- Testing automatizado
- Custom domain configuration

### 📋 Planeado
- Rate limiting configurado
- Cloud Armor integration
- Multi-región deployment

---

**Última Actualización:** 2024-01-15  
**Mantenedor:** Equipo de Infraestructura Allygo  
**Licencia:** Proyecto interno

---

## 🎓 Tips Finales

> 💡 **Tip 1:** Siempre ejecuta `.\sync-openapi.ps1` después de modificar `openapi.yaml`

> 💡 **Tip 2:** Usa `terraform plan` antes de `terraform apply` para revisar cambios

> 💡 **Tip 3:** Guarda [CHEATSHEET.md](CHEATSHEET.md) en tus favoritos para referencia rápida

> 💡 **Tip 4:** Lee [ARCHITECTURE.md](ARCHITECTURE.md) para entender el flujo completo

> 💡 **Tip 5:** Revisa logs regularmente: `gcloud logging tail "resource.type=api"`

---

**¡Bienvenido al proyecto API Gateway de Allygo!** 🚀
