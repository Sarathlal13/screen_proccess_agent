let videoElement;
let captureInterval;

function startScreenCapture(intervalSeconds = 3) {
  navigator.mediaDevices.getDisplayMedia({ video: true })
    .then(stream => {
      videoElement = document.createElement('video');
      videoElement.srcObject = stream;
      videoElement.play();

      captureInterval = setInterval(() => {
        const canvas = document.createElement('canvas');
        canvas.width = videoElement.videoWidth;
        canvas.height = videoElement.videoHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(videoElement, 0, 0);
        const imageData = canvas.toDataURL('image/png');
        window.dispatchEvent(new CustomEvent('onScreenSnapshot', { detail: imageData }));
      }, intervalSeconds * 1000);
    })
    .catch(err => {
      console.error("Screen capture error:", err);
    });
}

function stopScreenCapture() {
  if (videoElement && videoElement.srcObject) {
    videoElement.srcObject.getTracks().forEach(track => track.stop());
  }
  clearInterval(captureInterval);
}