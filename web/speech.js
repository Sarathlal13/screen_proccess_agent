let recognition;
let finalTranscript = "";

// function startListening() {
//   const SpeechRecognition =
//     window.SpeechRecognition || window.webkitSpeechRecognition;
//   recognition = new SpeechRecognition();
//   recognition.continuous = true;
//   recognition.interimResults = true;
//   recognition.lang = "en-US";

//   recognition.onresult = function (event) {
//     let finalTranscript = "";

//     for (let i = event.resultIndex; i < event.results.length; ++i) {
//       if (event.results[i].isFinal) {
//         finalTranscript += event.results[i][0].transcript;
//       }
//     }

//     if (finalTranscript && window.onTranscriptReceived) {
//       window.onTranscriptReceived(finalTranscript.trim());
//     } else {
//       console.warn("⚠️ Dart callback not registered yet or empty transcript.");
//     }
//   };

//   recognition.start();
// }

function startListening() {
  const SpeechRecognition =
    window.SpeechRecognition || window.webkitSpeechRecognition;
  recognition = new SpeechRecognition();
  recognition.continuous = true;
  recognition.interimResults = false;
  recognition.lang = "en-US";

  recognition.onresult = function (event) {
    let finalTranscript = "";

    for (let i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) {
        finalTranscript += event.results[i][0].transcript;
      }
    }

    if (finalTranscript && window.onTranscriptReceived) {
      console.log("🗣️ Transcript received:", finalTranscript.trim());
      window.onTranscriptReceived(finalTranscript.trim());
    } else {
      console.warn("Dart callback not registered yet or empty transcript.");
    }
  };

  recognition.onend = function () {
    console.log(" Speech recognition ended, restarting...");
    recognition.start(); // Automatically restart
  };

  recognition.onerror = function (event) {
    console.error("Speech recognition error:", event.error);
  };

  recognition.start();
}

function stopListening() {
  if (recognition) recognition.stop();
}
