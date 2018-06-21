const METHODS = {
    jumpTop: function (responseCallback) {
      responseCallback();
      jump(getBaseUrl());
    },
    goMypage: function (responseCallback) {
      clickElement(
        'li.btn-mypage > a',
        responseCallback,
        clickElement.bind(
          null,
          'div.mypage_btn > a',
          responseCallback
        )
      )
    },
    goGacha: function (responseCallback) {
      clickElement('div.ico-gacha > a', responseCallback);
    },
    goGachaNormalTab: function (responseCallback) {
      clickElement('div#gacha > ul > li:nth-child(3) > a', responseCallback);
    },
    drawKizunaGacha: function (responseCallback) {
      // まず周年ガチャを引いてみる
      clickElement(
        'img.btn-gacha',
        responseCallback,
        function () {
          // 次に10000絆Pガチャ
          clickElement(
            'a.btn-gacha[href*="' + convertUrl('gacha/gacha_draw') + '"]',
            responseCallback
          );
        }
      );
    },
    goGachaQuestTab: function (responseCallback) {
      clickElement('div#gacha > ul > li:nth-child(2) > a', responseCallback);
    },
    drawQuestGacha: function (responseCallback) {
      clickElement('a.btn-gacha[href*="' + convertUrl('gacha/gacha_draw/10') + '"]', responseCallback);
    },
    goRaidList: function (responseCallback) {
      clickElement('div.ico-resque > a', responseCallback);
    },
    goRaidHelp: function (responseCallback) {
      clickElement('div#raid div.o-float-c > a', responseCallback);
    },
    attackRaidFree: function (responseCallback) {
      clickElement('div#raid div.o-talign-c.o-mt-10 > a', responseCallback);
    },
    attackRaid20: function (responseCallback) {
      clickElement('div#raid div.o-col-2.o-mat-10.o-w-90.o-talign-c a', responseCallback);
    },
    // ロワイヤルの必殺技
    attackRaidDeathblow: function (responseCallback) {
      clickElement('div#raid img[src*="' + convertUrl('raid/button/skill_0bp.png') + '"]', responseCallback);
    },
    goOwnRaid: function (responseCallback) {
      clickElement('div.ico-appear > a', responseCallback);
    },
    requestRaidHelp: function (responseCallback) {
      clickElement('div#raid div.o-mt-10.o-talign-c > a', responseCallback);
    },
    goQuest: function (responseCallback) {
      clickElement('div.btn-quest > a', responseCallback);
    },
    goQuestHakenTab: function (responseCallback) {
      clickElement('div#quest a[href*="' + convertUrl('quest/index/2') + '"]', responseCallback);
    },
    goQuestGenteiTab: function (responseCallback) {
      clickElement('div#quest a[href*="' + convertUrl('quest/index/1') + '"]', responseCallback);
    },
    useHakenTicket: function (responseCallback) {
      clickElement('div.quest_list > a[href*=use_hegemony_ticket]', responseCallback);
    },
    questExec: function (responseCallback) {
      clickElement('div.quest_list > a[href*=quest_exec]', responseCallback);
    },
    attackQuestBoss: function (responseCallback) {
      clickElement('div#quest a[href*="' + convertUrl('quest/boss_battle_flash') + '"]', responseCallback);
    },
    questItemChallenge: function (responseCallback) {
      clickFlash(responseCallback);
    },
    goLottery: function (responseCallback) {
      clickNews(convertUrl('login_bonus/lottery'), responseCallback);
    },
    drawLottery: function (responseCallback) {
      clickElement('div#coin_kuji a[href*="' + convertUrl('login_bonus/lottery_exec') + '"]', responseCallback);
    },
    getRaidReward: function (responseCallback) {
      clickNews(convertUrl('raid/get_reward_all'), responseCallback);
    },
    goPresent: function (responseCallback) {
      clickNews('present', responseCallback);
    },
    getPresentAll: function (responseCallback) {
      clickElement('div#gift a[href*="' + convertUrl('present/receive_presents') + '"]', responseCallback);
    },
    goGrow: function (responseCallback) {
      clickNews(convertUrl('grow/index'), responseCallback);
    },
    confirmGrowItem: function (responseCallback) {
      clickElement('div.o-talign-c a.popup-btn.js-item_used_confirm', responseCallback);
    },
    useGrowItem: function (responseCallback) {
      clickElement('a[href*="' + convertUrl('grow/use_item/2') + '"]', responseCallback);
    },
    battleGrow: function (responseCallback) {
      clickElement('a[href*="' + convertUrl('grow/battle_flash') + '"]', responseCallback);
    },
    // AP回復リクエスト
    sendApRecoverRequest: function (responseCallback) {
      clickElement('div#quest img[src*="' + convertUrl('mafia/button/req_send.png') + '"]', responseCallback);
    },
    // AP回復ボタン
    recoverAp: function (responseCallback) {
      if (isMobage()) {
        clickElement('a[href*="' + convertUrl('comeback/comeback_result') + '"]', responseCallback);
      }
      else {
        // TODO 実装
        if (responseCallback) {
          responseCallback({
            result: true
          });
        }
      }
    },
};

function clickNews(href, callback)
{
  clickElement(`div.js-popup ul.linkList li > a[href*="${href}"]`, callback);
}

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

function clickElement(selector, successCallback, failCallback = null) {
   let element = getElement(selector);
   if (element) {
     successCallback();
     element.click();
     return;
   }

   if (failCallback) {
     failCallback({
       result: false
     });
   } else {
     successCallback({
       result: false
     });
   }
}

function getElement(selector) {
  let result = document.querySelector(selector);
  if (!result) {
    warn(selector + " element not found.");
  }
  return result;
}

function getBaseUrl(){
  return location.protocol + "//" + location.host;
}

function isMobage(url){
  return getBaseUrl() == 'http://g12024505.sp.pf.mbga.jp';
}

function convertUrl(url){
  // mobageの場合はurlをurlencodeする
  if (isMobage()) {
    return encodeURIComponent(url);
  }
  return url;
}

function clickFlash(callback) {
  let cvs = getElement('canvas');

  if (!cvs) {
    callback();
    return;
  }

  // flashが表示されるまで少し待つ
  setTimeout(function () {
    let evt = document.createEvent('MouseEvents');

    evt.initMouseEvent(
      'mousedown',
      true,
      true,
      window,
      1,
      0,
      0,
      cvs.getBoundingClientRect().x + cvs.style.width.match(/[0-9]*/)[0]/2,
      cvs.getBoundingClientRect().y + cvs.style.height.match(/[0-9]*/)[0]/2,
      false,
      false,
      false,
      0,
      null
    );
    cvs.dispatchEvent(evt);
    callback();
  }, 3000);

}

window.onload = function () {
  //メッセージリスナー
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    info("message received. -> " + JSON.stringify(request));
    METHODS[request.methodName](sendResponse);

    return true;
  });
}
