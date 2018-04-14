var isRunning = false;

//メッセージリスナー
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  console.log("message received. : " + JSON.stringify(request));
  if (request.is_enabled) {
    start();
  } else {
    stop();
  }
  var response = {msg: "from main"};
  sendResponse(response);

  return true;
});

function stop() {
  if (!isRunning) {
    return;
  }

  console.log("stop!");
  isRunning = false;
}

function start() {
  if (isRunning) {
    return;
  }

  console.log("start!");
  isRunning = true;
}
