const TOP_URL = "http://gang-trump.gree-pf.net/";

const METHODS = {
    jump_top: function () {
      jump(TOP_URL);
    },
    go_mypage: function () {
      click_element('div.mypage_btn > a');
    },
    go_gacha: function () {
      click_element('div.ico-gacha > a');
    },
    go_gacha_normal_tab: function () {
      click_element('div#gacha > ul > li:nth-child(3) > a');
    },
    draw_10000_kizuna_gacha: function () {
      click_element('a.btn-gacha');
    },
    go_raid_list: function () {
      click_element('div.ico-raidWrap a');
      // click_element('div.ico-resque ico-new a');
      // TODO 精査が必要
    },
    go_raid_help: function () {
      click_element('div.o-float-c > a');
    },
    attack_raid: function () {
      click_element('div#raid div.o-talign-c.o-mt-10 > a');
    },
    go_own_raid: function () {
      click_element('div.ico-appear > a');
    },
    request_raid_help: function () {
      click_element('div#raid div.o-mt-10.o-talign-c > a');
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
