import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "dropzoneLabel", "dropzoneUploading", "fileInput", "fileList", "uploadProgress"]
  static values = {
    url: String,
    chunkedUrl: String,
    workerUrl: String,
    chunkSize: { type: Number, default: 5 * 1024 * 1024 },
    schemaName: { type: String, default: "" }
  }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    this.activeUploads = new Map()
    this.uploading = false
  }

  disconnect() {
    this.activeUploads.forEach(entry => entry.worker.terminate())
    this.activeUploads.clear()
  }

  get isChunkedMode() {
    return this.hasWorkerUrlValue && this.hasChunkedUrlValue
  }

  openFilePicker(e) {
    e.preventDefault()
    if (this.uploading) return
    this.fileInputTarget.click()
  }

  handleDragOver(e) {
    e.preventDefault()
    e.stopPropagation()
    if (this.uploading) return
    this.dropzoneTarget.classList.add("dragover")
  }

  handleDragLeave(e) {
    e.preventDefault()
    e.stopPropagation()
    this.dropzoneTarget.classList.remove("dragover")
  }

  handleDrop(e) {
    e.preventDefault()
    e.stopPropagation()
    this.dropzoneTarget.classList.remove("dragover")
    if (this.uploading) return

    const files = Array.from(e.dataTransfer.files)
    this.uploadFiles(files)
  }

  handleFileSelect(e) {
    const files = Array.from(e.target.files)
    this.uploadFiles(files)
  }

  uploadFiles(files) {
    const xlsxFiles = files.filter(f =>
      f.name.endsWith(".xlsx") || f.name.endsWith(".xls")
    )

    if (xlsxFiles.length === 0) {
      this.dispatch("validation-error", { detail: { message: "Please select XLSX or XLS files" } })
      return
    }

    this.displayFileList(xlsxFiles)
    this.setUploadingState(true)

    if (this.isChunkedMode) {
      xlsxFiles.forEach(file => this.uploadChunked(file))
    } else {
      this.uploadLegacy(xlsxFiles)
    }
  }

  // --- Chunked upload via Web Worker ---

  uploadChunked(file) {
    const worker = new Worker(this.workerUrlValue)
    this.activeUploads.set(file.name, { worker, file })

    worker.onmessage = (event) => this.handleWorkerMessage(file.name, event.data)

    worker.postMessage({
      command: "start",
      payload: {
        file,
        chunkedUrl: this.chunkedUrlValue,
        chunkSize: this.chunkSizeValue,
        csrfToken: this.csrfToken,
        schemaName: this.schemaNameValue
      }
    })

    this.updateFileProgress(file.name, 0, "uploading")
  }

  retryUpload(fileName) {
    const entry = this.activeUploads.get(fileName)
    if (!entry) return

    entry.worker.terminate()

    const worker = new Worker(this.workerUrlValue)
    entry.worker = worker

    worker.onmessage = (event) => this.handleWorkerMessage(fileName, event.data)

    worker.postMessage({
      command: "resume",
      payload: {
        file: entry.file,
        chunkedUrl: this.chunkedUrlValue,
        uploadToken: entry.uploadToken,
        csrfToken: this.csrfToken,
        chunkSize: this.chunkSizeValue
      }
    })

    this.updateFileProgress(fileName, entry.lastProgress || 0, "uploading")
  }

  abortUpload(fileName) {
    const entry = this.activeUploads.get(fileName)
    if (!entry) return

    entry.worker.postMessage({ command: "abort" })
  }

  handleWorkerMessage(fileName, message) {
    const entry = this.activeUploads.get(fileName)

    switch (message.type) {
      case "initiated":
        if (entry) entry.uploadToken = message.data.upload_token
        break

      case "chunk_uploaded":
        if (entry) entry.lastProgress = message.progressPercent
        this.updateFileProgress(fileName, message.progressPercent, "uploading")
        break

      case "chunk_skipped":
        break

      case "complete":
        this.clearFileList()
        this.cleanupWorker(fileName)
        this.dispatch("uploaded", { detail: message.data })
        if (this.activeUploads.size === 0) {
          this.setUploadingState(false)
        }
        break

      case "chunk_failed":
        if (entry) entry.lastProgress = message.progressPercent || 0
        this.updateFileProgress(fileName, entry?.lastProgress || 0, "failed")
        this.setUploadingState(false)
        this.dispatch("upload-error", {
          detail: { fileName, error: message.error, uploadToken: message.uploadToken, retryable: true }
        })
        break

      case "error":
        this.updateFileProgress(fileName, 0, "failed")
        this.cleanupWorker(fileName)
        this.setUploadingState(false)
        this.dispatch("upload-error", { detail: { fileName, error: message.error } })
        break

      case "aborted":
        this.updateFileProgress(fileName, entry?.lastProgress || 0, "aborted")
        break
    }
  }

  cleanupWorker(fileName) {
    const entry = this.activeUploads.get(fileName)
    if (entry) {
      entry.worker.terminate()
      this.activeUploads.delete(fileName)
    }
  }

  // --- Legacy single-POST upload ---

  async uploadLegacy(files) {
    this.showProgress()

    const formData = new FormData()
    files.forEach(file => formData.append("files[]", file))

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        body: formData,
        headers: { "X-CSRF-Token": this.csrfToken }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.dispatch("uploaded", { detail: data })
      this.hideProgress()
      this.clearFileList()
      this.fileInputTarget.value = ""
      this.setUploadingState(false)
    } catch (error) {
      this.dispatch("upload-error", { detail: { error: error.message } })
      this.hideProgress()
      this.setUploadingState(false)
    }
  }

  // --- UI helpers ---

  setUploadingState(active) {
    this.uploading = active
    this.dropzoneTarget.classList.toggle("rowdy-dropzone-area--uploading", active)
    if (this.hasDropzoneLabelTarget) {
      this.dropzoneLabelTarget.classList.toggle("hidden", active)
    }
    if (this.hasDropzoneUploadingTarget) {
      this.dropzoneUploadingTarget.classList.toggle("hidden", !active)
    }
  }

  displayFileList(files) {
    this.fileListTarget.innerHTML = files.map(file => `
      <div class="rowdy-file-item" data-file-name="${file.name}">
        <svg class="rowdy-file-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
        </svg>
        <span class="rowdy-file-name">${file.name}</span>
        <span class="rowdy-file-size">${this.formatFileSize(file.size)}</span>
        <span class="rowdy-file-status" data-status="pending"></span>
        <div class="rowdy-file-progress-bar">
          <div class="rowdy-file-progress-fill" style="width: 0%"></div>
        </div>
      </div>
    `).join("")
  }

  updateFileProgress(fileName, percent, status) {
    const fileItem = this.fileListTarget.querySelector(`[data-file-name="${fileName}"]`)
    if (!fileItem) return

    const fill = fileItem.querySelector(".rowdy-file-progress-fill")
    const statusEl = fileItem.querySelector(".rowdy-file-status")

    if (fill) fill.style.width = `${percent}%`
    if (statusEl) statusEl.setAttribute("data-status", status)
  }

  clearFileList() {
    this.fileListTarget.innerHTML = ""
  }

  showProgress() {
    this.uploadProgressTarget.classList.remove("hidden")
  }

  hideProgress() {
    this.uploadProgressTarget.classList.add("hidden")
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
  }
}
