import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "rowdy_pending_uploads"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "fileList", "uploadProgress", "resume"]
  static values = {
    url: String,
    chunkedUrl: String,
    workerUrl: String,
    chunkSize: { type: Number, default: 5 * 1024 * 1024 }
  }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    this.activeUploads = new Map()
    this.resumingToken = null

    if (this.isChunkedMode && this.hasResumeTarget) {
      const pending = this.loadPendingUploads()
      if (Object.keys(pending).length > 0) {
        this.showResumeBanner(pending)
      }
    }
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
    this.fileInputTarget.click()
  }

  handleDragOver(e) {
    e.preventDefault()
    e.stopPropagation()
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

    const files = Array.from(e.dataTransfer.files)
    this.uploadFiles(files)
  }

  handleFileSelect(e) {
    const files = Array.from(e.target.files)

    if (this.resumingToken) {
      this.handleResumeFileSelect(files)
      return
    }

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
        csrfToken: this.csrfToken
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
        if (entry) {
          entry.uploadToken = message.data.upload_token
          this.savePendingUpload(
            message.data.upload_token,
            fileName,
            entry.file.size,
            this.chunkSizeValue
          )
        }
        break

      case "chunk_uploaded":
        if (entry) {
          entry.lastProgress = message.progressPercent
          this.updatePendingProgress(entry.uploadToken, message.progressPercent)
        }
        this.updateFileProgress(fileName, message.progressPercent, "uploading")
        break

      case "chunk_skipped":
        break

      case "complete":
        console.log("Upload complete - entry:", entry, "uploadToken:", entry?.uploadToken)
        if (entry?.uploadToken) {
          this.removePendingUpload(entry.uploadToken)
        } else {
          console.warn("No uploadToken found to remove from pending")
        }
        this.updateFileProgress(fileName, 100, "completed")
        this.cleanupWorker(fileName)
        this.dispatch("uploaded", { detail: message.data })
        break

      case "chunk_failed":
        if (entry) entry.lastProgress = message.progressPercent || 0
        this.updateFileProgress(fileName, entry?.lastProgress || 0, "failed")
        this.dispatch("upload-error", {
          detail: { fileName, error: message.error, uploadToken: message.uploadToken, retryable: true }
        })
        break

      case "error":
        if (entry) this.removePendingUpload(entry.uploadToken)
        this.updateFileProgress(fileName, 0, "failed")
        this.cleanupWorker(fileName)
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

  // --- Cross-session resume (localStorage) ---

  savePendingUpload(uploadToken, fileName, fileSize, chunkSize) {
    const pending = this.loadPendingUploads()
    pending[uploadToken] = { uploadToken, fileName, fileSize, chunkSize, progressPercent: 0 }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(pending))
  }

  updatePendingProgress(uploadToken, progressPercent) {
    if (!uploadToken) return
    const pending = this.loadPendingUploads()
    if (pending[uploadToken]) {
      pending[uploadToken].progressPercent = progressPercent
      localStorage.setItem(STORAGE_KEY, JSON.stringify(pending))
    }
  }

  removePendingUpload(uploadToken) {
    if (!uploadToken) return
    const pending = this.loadPendingUploads()
    delete pending[uploadToken]
    localStorage.setItem(STORAGE_KEY, JSON.stringify(pending))
  }

  loadPendingUploads() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}
    } catch {
      return {}
    }
  }

  showResumeBanner(pendingUploads) {
    const entries = Object.values(pendingUploads)
    if (entries.length === 0) {
      this.resumeTarget.classList.add("hidden")
      return
    }

    this.resumeTarget.classList.remove("hidden")
    this.resumeTarget.innerHTML = entries.map(entry => `
      <div class="rowdy-resume-item" data-upload-token="${entry.uploadToken}">
        <div class="rowdy-resume-info">
          <span class="rowdy-resume-filename">${entry.fileName}</span>
          <span class="rowdy-resume-progress">${entry.progressPercent}% uploaded</span>
        </div>
        <div class="rowdy-resume-actions">
          <button type="button" class="rowdy-resume-btn" data-action="click->rowdy-dropzone#startResume" data-token="${entry.uploadToken}">
            Select file to resume
          </button>
          <button type="button" class="rowdy-resume-dismiss-btn" data-action="click->rowdy-dropzone#dismissResume" data-token="${entry.uploadToken}">
            Dismiss
          </button>
        </div>
      </div>
    `).join("")
  }

  startResume(event) {
    const token = event.currentTarget.dataset.token
    this.resumingToken = token
    this.fileInputTarget.setAttribute("multiple", false)
    this.fileInputTarget.click()
  }

  handleResumeFileSelect(files) {
    const token = this.resumingToken
    this.resumingToken = null
    this.fileInputTarget.setAttribute("multiple", true)
    this.fileInputTarget.value = ""

    if (!token || files.length === 0) return

    const pending = this.loadPendingUploads()
    const entry = pending[token]
    if (!entry) return

    const file = files[0]

    if (file.name !== entry.fileName || file.size !== entry.fileSize) {
      this.dispatch("validation-error", {
        detail: { message: "File does not match the interrupted upload" }
      })
      return
    }

    this.hideResumeBannerItem(token)
    this.displayFileList([file])

    const worker = new Worker(this.workerUrlValue)
    this.activeUploads.set(file.name, {
      worker,
      file,
      uploadToken: token,
      lastProgress: entry.progressPercent
    })

    worker.onmessage = (event) => this.handleWorkerMessage(file.name, event.data)

    worker.postMessage({
      command: "resume",
      payload: {
        file,
        chunkedUrl: this.chunkedUrlValue,
        uploadToken: token,
        csrfToken: this.csrfToken,
        chunkSize: entry.chunkSize
      }
    })

    this.updateFileProgress(file.name, entry.progressPercent, "uploading")
  }

  dismissResume(event) {
    const token = event.currentTarget.dataset.token
    this.removePendingUpload(token)
    this.hideResumeBannerItem(token)
  }

  hideResumeBannerItem(token) {
    const item = this.resumeTarget.querySelector(`[data-upload-token="${token}"]`)
    if (item) item.remove()

    if (this.resumeTarget.children.length === 0) {
      this.resumeTarget.classList.add("hidden")
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

    } catch (error) {
      this.dispatch("upload-error", { detail: { error: error.message } })
      this.hideProgress()
    }
  }

  // --- UI helpers ---

  displayFileList(files) {
    this.fileListTarget.innerHTML = files.map(file => `
      <div class="rowdy-file-item" data-file-name="${file.name}">
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
