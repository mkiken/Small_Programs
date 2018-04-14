const TOP_URL = "http://gang-trump.gree-pf.net/";

const METHODS = {
    jump_top: function () {
      jump(TOP_URL);
    },
    go_mypage: function () {
      click_element('div.mypage_btn');
    },
};

//メッセージリスナー
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  info("message received. -> " + JSON.stringify(request));
  METHODS[request.method_name]();
  var response = {msg: "from main"};
  sendResponse(response);

  return true;
});

function jump(url) {
  info("url -> " + url);
  window.location.href = url;
}

function info(msg) {
  console.log(createLogMessage(msg));
}

function warn(msg) {
  console.warn(createLogMessage(msg));
}

function createLogMessage(msg) {
  return (new Date()).toString() + ": " + msg;
}

function click_element(selector) {
   let element = get_element(selector);
   if (element) {
     element.click();
   }
}

function get_element(selector) {
  let result = document.querySelector(selector);
  if (!result) {
    warn(selector + " element not found.");
  }
  return result;
}
