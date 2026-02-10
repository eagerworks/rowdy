import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "fileInput", "fileList", "uploadProgress"]
  static values = { url: String }

  connect = () => this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

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
    this.uploadFiles(files)
  }

  async uploadFiles(files) {
    const xlsxFiles = files.filter(f =>
      f.name.endsWith('.xlsx') || f.name.endsWith('.xls')
    )

    if (xlsxFiles.length === 0) {
      alert('Please select XLSX or XLS files')
      return
    }

    this.showProgress()
    this.displayFileList(xlsxFiles)

    const formData = new FormData()
    xlsxFiles.forEach(file => formData.append('files[]', file))

    try {
      console.log("uploading files to", this.urlValue)
      const response = await fetch(this.urlValue, {
        method: 'POST',
        body: formData,
        headers: { 'X-CSRF-Token': this.csrfToken }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.dispatch("uploaded", { detail: data })
      this.hideProgress()
      this.clearFileList()
      this.fileInputTarget.value = ''

    } catch (error) {
      console.error('Upload failed:', error)
      alert('Upload failed: ' + error.message)
      this.hideProgress()
    }
  }

  displayFileList(files) {
    this.fileListTarget.innerHTML = files.map(file => `
      <div class="rowdy-file-item">
        <span>${file.name}</span>
        <span>${this.formatFileSize(file.size)}</span>
      </div>
    `).join('')
  }

  clearFileList() {
    this.fileListTarget.innerHTML = ''
  }

  showProgress() {
    this.uploadProgressTarget.classList.remove('hidden')
    this.uploadProgressTarget.textContent = 'Uploading files...'
  }

  hideProgress() {
    this.uploadProgressTarget.classList.add('hidden')
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
}
