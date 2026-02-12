self.onmessage = async (event) => {
  const { command, payload } = event.data

  switch (command) {
    case "start":
      handleStart(payload)
      break
    case "resume":
      handleResume(payload)
      break
    case "abort":
      handleAbort()
      break
  }
}

let currentUpload = null
let abortController = null

async function handleStart(payload) {
  const { file, chunkedUrl, chunkSize, csrfToken } = payload

  currentUpload = {
    file,
    chunkedUrl,
    chunkSize,
    csrfToken,
    uploadToken: null,
    uploadedChunks: new Set()
  }

  abortController = new AbortController()

  try {
    // Initiate upload
    const initiateResponse = await fetch(chunkedUrl, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        filename: file.name,
        size: file.size,
        chunk_size: chunkSize
      }),
      signal: abortController.signal
    })

    if (!initiateResponse.ok) {
      throw new Error(`Failed to initiate upload: ${initiateResponse.status}`)
    }

    const initiateData = await initiateResponse.json()
    currentUpload.uploadToken = initiateData.upload_token
    currentUpload.uploadedChunks = new Set(initiateData.received_chunks || [])

    // Notify controller
    self.postMessage({
      type: "initiated",
      data: initiateData
    })

    // Start uploading chunks
    await uploadChunks(file, chunkSize, chunkedUrl, csrfToken, initiateData.upload_token)
  } catch (error) {
    if (error.name === "AbortError") {
      self.postMessage({ type: "aborted" })
    } else {
      self.postMessage({
        type: "error",
        error: error.message
      })
    }
    currentUpload = null
  }
}

async function handleResume(payload) {
  const { file, chunkedUrl, uploadToken, csrfToken, chunkSize } = payload

  currentUpload = {
    file,
    chunkedUrl,
    chunkSize,
    csrfToken,
    uploadToken,
    uploadedChunks: new Set()
  }

  abortController = new AbortController()

  try {
    // Get upload status
    const statusResponse = await fetch(`${chunkedUrl}/${uploadToken}`, {
      method: "GET",
      headers: {
        "X-CSRF-Token": csrfToken
      },
      signal: abortController.signal
    })

    if (statusResponse.ok) {
      const statusData = await statusResponse.json()
      currentUpload.uploadedChunks = new Set(statusData.received_chunks || [])
    }

    // Resume uploading chunks
    await uploadChunks(file, chunkSize, chunkedUrl, csrfToken, uploadToken)
  } catch (error) {
    if (error.name === "AbortError") {
      self.postMessage({ type: "aborted" })
    } else {
      self.postMessage({
        type: "error",
        error: error.message
      })
    }
    currentUpload = null
  }
}

function handleAbort() {
  if (abortController) {
    abortController.abort()
  }
}

async function uploadChunks(file, chunkSize, chunkedUrl, csrfToken, uploadToken) {
  const chunks = Math.ceil(file.size / chunkSize)
  let uploadedCount = currentUpload.uploadedChunks.size

  for (let chunkIndex = 0; chunkIndex < chunks; chunkIndex++) {
    if (currentUpload.uploadedChunks.has(chunkIndex)) {
      self.postMessage({
        type: "chunk_skipped",
        chunkIndex
      })
      continue
    }

    try {
      const start = chunkIndex * chunkSize
      const end = Math.min(start + chunkSize, file.size)
      const chunk = file.slice(start, end)

      const uploadResponse = await fetch(`${chunkedUrl}/${uploadToken}/${chunkIndex}`, {
        method: "PUT",
        headers: {
          "X-CSRF-Token": csrfToken
        },
        body: chunk,
        signal: abortController.signal
      })

      if (!uploadResponse.ok) {
        throw new Error(`Chunk ${chunkIndex} upload failed: ${uploadResponse.status}`)
      }

      const uploadData = await uploadResponse.json()

      currentUpload.uploadedChunks.add(chunkIndex)
      uploadedCount++
      console.log(`Chunk ${chunkIndex} uploaded successfully - total uploaded: ${uploadedCount}/${chunks}`)

      const progressPercent = Math.round((uploadedCount / chunks) * 100)

      self.postMessage({
        type: "chunk_uploaded",
        chunkIndex,
        progressPercent
      })

      // Check if all chunks are uploaded
      console.log(`uploadedCount: ${uploadedCount}, total chunks: ${chunks}`)
      if (uploadedCount === chunks) {
        // Complete the upload
        const completeResponse = await fetch(`${chunkedUrl}/${uploadToken}/complete`, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken
          },
          signal: abortController.signal
        })

        if (!completeResponse.ok) {
          throw new Error(`Failed to complete upload: ${completeResponse.status}`)
        }

        const completeData = await completeResponse.json()
        console.log("Upload complete - server response:", completeData)
        console.log("Notifying main thread of completion with data:", completeData)
        self.postMessage({
          type: "complete",
          data: completeData
        })

        currentUpload = null
        break
      }
    } catch (error) {
      if (error.name === "AbortError") {
        self.postMessage({ type: "aborted" })
      } else {
        self.postMessage({
          type: "chunk_failed",
          chunkIndex,
          error: error.message,
          uploadToken,
          progressPercent: Math.round((uploadedCount / chunks) * 100)
        })
      }
      currentUpload = null
      break
    }
  }
}
