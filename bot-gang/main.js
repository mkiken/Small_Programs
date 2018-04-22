const TOP_URL = "http://gang-trump.gree-pf.net/";

const METHODS = {
    jumpTop: function (responseCallback) {
      responseCallback();
      jump(TOP_URL);
    },
    goMypage: function (responseCallback) {
      clickElement(
        'li.btn-mypage > a',
        responseCallback,
        clickElement.bind(this, 'div.mypage_btn > a', responseCallback)
      )
    },
    goGacha: function (responseCallback) {
      clickElement('div.ico-gacha > a', responseCallback);
    },
    goGachaNormalTab: function (responseCallback) {
      clickElement('div#gacha > ul > li:nth-child(3) > a', responseCallback);
    },
    draw10000KizunaGacha: function (responseCallback) {
      clickElement('a.btn-gacha[href*="gacha/gacha_draw"]', responseCallback);
    },
    goGachaQuestTab: function (responseCallback) {
      clickElement('div#gacha > ul > li:nth-child(2) > a', responseCallback);
    },
    drawQuestGacha: function (responseCallback) {
      clickElement('a.btn-gacha[href*="gacha/gacha_draw"]', responseCallback);
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
      clickElement('div#quest > ul > li:nth-child(3) > a[href*="quest/index/2"]', responseCallback);
    },
    goQuestGenteiTab: function (responseCallback) {
      clickElement('div#quest > ul > li:nth-child(2) > a[href*="quest/index/1"]', responseCallback);
    },
    questExec: function (responseCallback) {
      clickElement('div.quest_list > a[href*=quest_exec]', responseCallback);
    },
    attackQuestBoss: function (responseCallback) {
      clickElement('div#quest a[href*="quest/boss_battle_flash"]', responseCallback);
    },
    questItemChallenge: function (responseCallback) {
      // TODO 動かないので直す
      clickElement('div#reel > canvas', responseCallback);
    },
    goLottery: function (responseCallback) {
      clickNews('login_bonus/lottery', responseCallback);
    },
    drawLottery: function (responseCallback) {
      clickElement('div#coin_kuji a[href*="login_bonus/lottery_exec"]', responseCallback);
    },
    getRaidReward: function (responseCallback) {
      clickNews('raid/get_reward_all', responseCallback);
    },
    goPresent: function (responseCallback) {
      clickNews('present', responseCallback);
    },
    getPresentAll: function (responseCallback) {
      clickElement('div#gift a[href*="present/receive_presents"]', responseCallback);
    },
};

//メッセージリスナー
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  info("message received. -> " + JSON.stringify(request));
  METHODS[request.methodName](sendResponse);

  return true;
});

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
