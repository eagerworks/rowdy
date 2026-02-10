# Rowdy v1 - Scope Final

## Decisiones de Diseño Confirmadas

### 1. ✅ Sin mecanismo de actualización de UI
**Decisión:** El engine NO provee ningún mecanismo de actualización automática.

**Razón:** Máxima portabilidad. El host elige su stack (Turbo, Alpine, React, Vue, polling manual, etc).

**Implementación:**
- Engine expone API REST con JSON
- Worker actualiza estado en DB
- ViewComponents renderizan HTML estático
- El host consume el API como prefiera

### 2. ✅ ViewComponents solo HTML estático
**Decisión:** ViewComponents renderizan HTML puro con data-attributes.

**Razón:** Sin asumir JavaScript específico. El host agrega JS si quiere.

**Implementación:**
- IDs únicos: `id="upload-123"`
- Data attributes: `data-upload-id`, `data-upload-status`
- Clases CSS: `.rowdy-upload-item`, `.rowdy-upload-progress-bar`
- NO incluir: `data-controller`, `data-action`, ni otros bindings de Stimulus

### 3. ✅ Worker actualiza DB, sin broadcasts
**Decisión:** El worker solo actualiza columnas en la base de datos.

**Razón:** No asumir tecnología de tiempo real (Action Cable, Redis, Turbo).

**Implementación:**
- Worker actualiza `status` y `progress` en DB
- NO hace broadcasts a ningún canal
- NO depende de Redis (solo Sidekiq lo necesita)

---

## Scope de v1

### ✅ Incluido en v1 (Core Agnóstico)

#### Backend
1. **Modelo `Rowdy::Upload`**
   - Estados: pending, processing, completed, failed
   - Progress: 0-100
   - ActiveStorage attachments (input_file, output_file)
   - Metadata serializado como JSON

2. **API REST con JSON**
   - `POST /rowdy/uploads` - Crear uploads (múltiples archivos)
   - `GET /rowdy/uploads/:id` - Estado actual (JSON)
   - `GET /rowdy/uploads/:id/download` - Descargar resultado

3. **Worker asíncrono**
   - `Rowdy::ProcessUploadJob`
   - Procesador pluggable (lambda configurable)
   - Actualiza `status` y `progress` en DB
   - Manejo de errores con `error_message`

4. **Sistema de configuración**
   - `Rowdy.configure { |c| c.processor = -> { } }`
   - Procesador por defecto (identity)

#### Frontend
5. **ViewComponents básicos**
   - `Rowdy::DropzoneComponent` - Upload drag & drop
   - `Rowdy::UploadListComponent` - Lista de uploads
   - `Rowdy::UploadItemComponent` - Item individual
   - HTML puro + data-attributes

6. **Stimulus controller del dropzone**
   - `rowdy_dropzone_controller.js`
   - Solo maneja drag & drop y POST al API
   - NO maneja actualización de progreso

### ❌ Excluido de v1

#### NO incluir
1. ❌ Turbo Streams / Hotwire
   - Sin `turbo_stream_from`
   - Sin `turbo_frame_tag`
   - Sin broadcasts de Turbo

2. ❌ Polling automático
   - Sin `rowdy_upload_list_controller.js` con polling
   - El host lo implementa si quiere

3. ❌ WebSockets / Action Cable
   - Sin channels
   - Sin broadcasts
   - Sin dependencia de Redis para UI

4. ❌ Plugins de integración
   - Sin `Rowdy::TurboStreamsIntegration`
   - Sin `Rowdy::SSEIntegration`
   - Sin helpers de integración con otros frameworks

5. ❌ JavaScript de actualización
   - Sin lógica de polling en el engine
   - Sin manejo de eventos de progreso
   - Solo el dropzone tiene JS (upload)

---

## Contratos de API (Definitivos)

### POST /rowdy/uploads
**Request:** `multipart/form-data` con `files[]`

**Response:**
```json
{
  "upload_ids": [1, 2, 3],
  "message": "3 files uploaded successfully"
}
```

**Uso:** El dropzone hace POST, recibe IDs, puede redirectear o mostrar mensaje.

---

### GET /rowdy/uploads/:id
**Response:**
```json
{
  "id": 1,
  "filename": "datos.xlsx",
  "size": 1024000,
  "status": "processing",
  "progress": 67,
  "error_message": null,
  "created_at": "2026-02-06T12:00:00Z",
  "updated_at": "2026-02-06T12:05:30Z"
}
```

**Uso:** El host puede:
- Hacer polling cada N segundos (vanilla JS, Stimulus, Alpine)
- Usar SSE para subscribirse (implementación del host)
- Usar Turbo Streams (implementación del host)
- Ignorarlo y solo mostrar el resultado final

---

### GET /rowdy/uploads/:id/download
**Response:** Stream del archivo procesado (ActiveStorage redirect)

**Headers:** `Content-Disposition: attachment`

**Requires:** `status == "completed"`

**Uso:** Link directo `<a href="/rowdy/uploads/1/download">Descargar</a>`

---

## Arquitectura de v1

```
┌─────────────────────────────────────────────────────────┐
│                    HOST APPLICATION                     │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Decide cómo actualizar UI (polling, Turbo, etc)  │ │
│  │  Implementa JS si quiere actualización automática │ │
│  └───────────────────────────────────────────────────┘ │
│                          │                              │
│                          ▼                              │
│  ┌───────────────────────────────────────────────────┐ │
│  │         ROWDY ENGINE (v1 - Core Agnóstico)        │ │
│  │                                                     │ │
│  │  1. API REST (JSON)                                │ │
│  │     - POST /uploads                                │ │
│  │     - GET  /uploads/:id                            │ │
│  │     - GET  /uploads/:id/download                   │ │
│  │                                                     │ │
│  │  2. ViewComponents (HTML estático)                 │ │
│  │     - Dropzone (con JS solo para upload)          │ │
│  │     - UploadList (solo HTML)                       │ │
│  │     - UploadItem (solo HTML)                       │ │
│  │                                                     │ │
│  │  3. Worker (actualiza DB)                          │ │
│  │     - ProcessUploadJob                             │ │
│  │     - Procesador pluggable                         │ │
│  │     - Actualiza status/progress en DB              │ │
│  │                                                     │ │
│  │  4. Modelo                                          │ │
│  │     - Rowdy::Upload                                │ │
│  │     - ActiveStorage attachments                    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Responsabilidades Definitivas

### Engine (Rowdy v1)

**DEBE:**
- ✅ Proveer API REST con JSON
- ✅ Proveer modelo de datos (`Rowdy::Upload`)
- ✅ Proveer worker asíncrono
- ✅ Proveer ViewComponents con HTML estático
- ✅ Proveer Stimulus controller para dropzone (solo upload)
- ✅ Actualizar `status` y `progress` en DB
- ✅ Ser agnóstico del stack frontend

**NO DEBE:**
- ❌ Asumir Turbo/Hotwire instalado
- ❌ Incluir mecanismos de actualización automática
- ❌ Hacer broadcasts a ningún canal
- ❌ Depender de Redis para UI
- ❌ Incluir JS de polling o actualización

### Host Application

**DEBE proveer:**
- ActiveStorage configurado (local/S3/GCS)
- Worker backend (Sidekiq, Resque, etc)
- Procesador custom (lógica de procesamiento XLSX)

**PUEDE elegir:**
- Cómo actualizar UI (polling, Turbo, SSE, manual, ninguno)
- Qué frontend usar (Stimulus, Alpine, React, Vue, vanilla)
- Autenticación/Autorización
- Estilos CSS

---

## Correcciones Necesarias al Código Actual

### 1. ✅ ViewComponents ya están correctos (HTML puro)
**Estado:** Ya corregidos en ediciones anteriores.

- `UploadItemComponent` usa IDs y data-attributes
- `UploadListComponent` usa contenedor con ID
- NO usan `turbo_frame_tag` ni `turbo_stream_from`

**Acción:** Ninguna corrección necesaria.

---

### 2. ⚠️ UploadListComponent tiene data-controller de Stimulus
**Estado:** Tiene `data-controller="rowdy-upload-list"` y `data-rowdy-upload-list-poll-interval-value="2000"`

**Problema:** Asume un controller que no existe (y no debe existir en v1).

**Corrección necesaria:**
```erb
<!-- Antes (incorrecto) -->
<div data-controller="rowdy-upload-list"
     data-rowdy-upload-list-poll-interval-value="2000">

<!-- Después (correcto v1) -->
<div id="rowdy-uploads-list">
```

**Razón:** v1 no incluye JS de actualización. El host agrega data-controller si quiere.

---

### 3. ⚠️ ProcessUploadJob tiene broadcasts de Turbo
**Estado:** Archivo tiene método `broadcast_update` y llama a `Turbo::StreamsChannel`.

**Problema:** Asume Turbo instalado.

**Corrección necesaria:**
- Remover método `broadcast_update`
- Remover todas las llamadas a `broadcast_update(upload)`

**Razón:** v1 solo actualiza DB, sin broadcasts.

---

### 4. ⚠️ Existe partial de Turbo
**Estado:** Existe `/app/views/rowdy/_upload_item_component.html.erb`

**Problema:** Solo se usa para broadcasts de Turbo.

**Corrección necesaria:**
- Eliminar el archivo

**Razón:** v1 no usa broadcasts, el partial no tiene propósito.

---

### 5. ⚠️ Documentación menciona Turbo
**Estado:** README y DEVELOPMENT.md mencionan Turbo Streams, Action Cable, Redis para UI.

**Problema:** Confunde sobre las dependencias reales.

**Corrección necesaria:**
- Remover todas las referencias a Turbo Streams
- Remover referencias a Action Cable para UI
- Aclarar que Redis solo es necesario para Sidekiq (workers)
- Remover sección "Progreso en tiempo real"
- Actualizar troubleshooting

**Razón:** v1 no tiene actualización automática de UI.

---

## Flujo de Uso de v1

### Caso 1: Sin actualización de UI (mínimo)

```ruby
# Host app: app/views/documents/new.html.erb
<h1>Subir archivos</h1>

<%= render Rowdy::DropzoneComponent.new %>

<p>Después de subir, revisá el estado:</p>
<%= link_to "Ver mis uploads", uploads_path %>
```

Usuario:
1. Drag & drop archivos
2. Archivos se suben (POST /rowdy/uploads)
3. Usuario ve link "Ver mis uploads"
4. Usuario hace click y ve lista con estados

**UX:** Básica, sin tiempo real, pero funcional.

---

### Caso 2: Con polling manual (host implementa)

```javascript
// Host app implementa su propio polling
document.addEventListener('DOMContentLoaded', () => {
  const uploadItems = document.querySelectorAll('[data-upload-id]')

  uploadItems.forEach(item => {
    const uploadId = item.dataset.uploadId
    const status = item.dataset.uploadStatus

    if (status === 'processing' || status === 'pending') {
      pollUpload(uploadId, item)
    }
  })
})

function pollUpload(uploadId, element) {
  const interval = setInterval(async () => {
    const response = await fetch(`/rowdy/uploads/${uploadId}`)
    const data = await response.json()

    // Actualizar DOM manualmente
    element.querySelector('.rowdy-upload-status').textContent = data.status
    element.querySelector('.rowdy-upload-progress-text').textContent = `${data.progress}%`
    element.querySelector('progress').value = data.progress

    if (data.status === 'completed' || data.status === 'failed') {
      clearInterval(interval)
      location.reload() // O actualizar DOM para mostrar botón descarga
    }
  }, 2000)
}
```

**UX:** Tiempo real, implementado por el host.

---

### Caso 3: Con Turbo Streams (host implementa)

```ruby
# Host app implementa su propio broadcast
# app/models/concerns/broadcast_upload_updates.rb
module BroadcastUploadUpdates
  extend ActiveSupport::Concern

  included do
    after_update :broadcast_update, if: -> { saved_change_to_status? || saved_change_to_progress? }
  end

  def broadcast_update
    broadcast_replace_to "uploads",
      target: "upload-#{id}",
      partial: "uploads/upload_item",
      locals: { upload: self }
  end
end

# Host app incluye el concern
class Rowdy::Upload
  include BroadcastUploadUpdates
end
```

**UX:** Tiempo real con Turbo, implementado por el host.

---

## Testing de v1

### Test manual en dummy app

```bash
# 1. Subir archivo
# 2. Ver que aparece con status "pending"
# 3. Worker lo procesa (Sidekiq)
# 4. Refreshear página manualmente
# 5. Ver status "completed"
# 6. Click en "Descargar"
```

**Expectativa:** Sin tiempo real, pero funcional. El usuario refreshea para ver progreso.

---

## Documentación de v1

### README debe decir:

**Lo que v1 provee:**
- API REST para uploads
- ViewComponents básicos
- Worker asíncrono
- Procesador pluggable

**Lo que v1 NO provee:**
- Actualización automática de UI
- Mecanismo de tiempo real
- Polling built-in
- Integración con Turbo/Hotwire

**Cómo agregar actualización de UI:**
El host puede implementar:
- Polling con vanilla JS / Stimulus / Alpine
- Turbo Streams con callbacks propios
- SSE con endpoint custom
- WebSockets con Action Cable

Ver sección "Extensiones" para ejemplos.

---

## Ventajas de v1

### Para el engine
✅ Código simple y mantenible
✅ Sin dependencias opcionales
✅ Sin supuestos sobre el host
✅ Fácil de testear
✅ Portable a cualquier stack

### Para el host
✅ Elige su stack frontend libremente
✅ No se fuerza Turbo/Hotwire
✅ Puede agregar tiempo real si quiere
✅ O puede no agregar nada (refresh manual)
✅ API REST es estándar y consumible

---

## Roadmap Post-v1

### v1.1 (opcional): Ejemplos de integración
- Documentar polling con Stimulus (ejemplo)
- Documentar polling con Alpine (ejemplo)
- Documentar integración con Turbo (ejemplo)
- Documentar SSE (ejemplo)

**Nota:** Son ejemplos en documentación, no código en el engine.

### v2 (futuro): Plugins opcionales
- `Rowdy::TurboStreamsPlugin` (opt-in)
- `Rowdy::SSEPlugin` (opt-in)
- `Rowdy::PollingHelpers` (opt-in)

**Nota:** Plugins separados, no default.

---

## Resumen de v1

**Filosofía:** Engine agnóstico, host decide todo lo relacionado con UI.

**Scope:**
- Backend completo (API, modelo, worker)
- Frontend básico (HTML estático con hooks)
- Sin tiempo real ni actualización automática

**Resultado:**
- Engine portable y simple
- Host tiene control total de UX
- Fácil de entender y extender

**Estado actual:**
- Backend: ✅ Completo
- ViewComponents: ✅ Casi correctos (ajustes menores)
- Worker: ⚠️ Remover broadcasts
- Documentación: ⚠️ Actualizar para v1
