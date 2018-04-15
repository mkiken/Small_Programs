const TOP_URL = "http://gang-trump.gree-pf.net/";

const METHODS = {
    jump_top: function (response_callback) {
      response_callback();
      jump(TOP_URL);
    },
    go_mypage: function (response_callback) {
      click_element(
        'li.btn-mypage > a',
        response_callback,
        click_element.bind(this, 'div.mypage_btn > a', response_callback)
      )
    },
    go_gacha: function (response_callback) {
      click_element('div.ico-gacha > a', response_callback);
    },
    go_gacha_normal_tab: function (response_callback) {
      click_element('div#gacha > ul > li:nth-child(3) > a', response_callback);
    },
    draw_10000_kizuna_gacha: function (response_callback) {
      click_element('a.btn-gacha', response_callback);
    },
    go_raid_list: function (response_callback) {
      click_element('div.ico-resque > a', response_callback);
    },
    go_raid_help: function (response_callback) {
      click_element('div#raid div.o-float-c > a', response_callback);
    },
    attack_raid_free: function (response_callback) {
      click_element('div#raid div.o-talign-c.o-mt-10 > a', response_callback);
    },
    attack_raid_20: function (response_callback) {
      click_element('div#raid div.o-col-2.o-mat-10.o-w-90.o-talign-c a', response_callback);
    },
    go_own_raid: function (response_callback) {
      click_element('div.ico-appear > a', response_callback);
    },
    request_raid_help: function (response_callback) {
      click_element('div#raid div.o-mt-10.o-talign-c > a', response_callback);
    },
    go_quest: function (response_callback) {
      click_element('div.btn-quest > a', response_callback);
    },
    go_quest_haken_tab: function (response_callback) {
      click_element('div#quest > ul > li:nth-child(3) > a', response_callback);
    },
    go_quest_gentei_tab: function (response_callback) {
      click_element('div#quest > ul > li:nth-child(2) > a', response_callback);
    },
    quest_exec: function (response_callback) {
      click_element('div.quest_list > a[href*=quest_exec]', response_callback);
    },
};

//メッセージリスナー
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  info("message received. -> " + JSON.stringify(request));
  METHODS[request.method_name](sendResponse);

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

function click_element(selector, success_callback, fail_callback = null) {
   let element = get_element(selector);
   if (element) {
     success_callback();
     element.click();
     return;
   }

   if (fail_callback) {
     fail_callback();
   } else {
     success_callback();
   }
}

function get_element(selector) {
  let result = document.querySelector(selector);
  if (!result) {
    warn(selector + " element not found.");
  }
  return result;
}
