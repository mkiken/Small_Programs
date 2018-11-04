const SEQUENCES = [
  // ↓ レイド救援 ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'go raid list.',
    methodName: 'goRaidList',
    wait: 2,
    fail: {
      skipSteps: 4
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'go raid help.',
    methodName: 'goRaidHelp',
    wait: 2,
    fail: {
      skipSteps: 3
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'attack to raid.',
    methodName: 'attackRaidFree',
    wait: 3,
    success: {
      skip_step: 2,
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  // 自分で殴る
  {
    description: 'attack to raid deathblow.',
    methodName: 'attackRaidDeathblow',
    wait: 3,
    beforeFilter: function () {
      return isMafiaEvent;
    },
  },
  {
    description: 'attack to raid bp20.',
    methodName: 'attackRaid20',
    wait: 3,
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  // ↑ レイド救援 ↑
  // ↓ 自分のレイド ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
  },
  {
    description: 'go own raid',
    methodName: 'goOwnRaid',
    wait: 2,
    fail: {
      skipSteps: 8
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'go idol raid',
    methodName: 'goIdolRaid',
    wait: 2,
    fail: {
      skipSteps: 7
    },
    beforeFilter: function () {
      return isIdolEvent;
    },
  },
  {
    description: 'attack to raid free.',
    methodName: 'attackRaidFree',
    wait: 3,
    success: {
      skipSteps: 6
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  {
    description: 'attack to idol 50bp.',
    methodName: 'attackIdolRaid50',
    wait: 3,
    success: {
      skipSteps: 5
    },
    beforeFilter: function () {
      return isIdolEvent;
    },
  },
  {
    description: 'attack to idol 20bp.',
    methodName: 'attackIdolRaid20',
    wait: 3,
    success: {
      skipSteps: 4
    },
    beforeFilter: function () {
      return isIdolEvent;
    },
  },
  {
    description: 'attack to idol free.',
    methodName: 'attackIdolRaidFree',
    wait: 3,
    success: {
      skipSteps: 3
    },
    beforeFilter: function () {
      return isIdolEvent;
    },
  },
  // 無料で殴れなかったら救援
  {
    description: 'request raid help',
    methodName: 'requestRaidHelp',
    wait: 3,
    success: {
      skipSteps: 2
    },
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  // 救援できなかったら自分で殴る
  {
    description: 'attack to raid deathblow.',
    methodName: 'attackRaidDeathblow',
    wait: 3,
    beforeFilter: function () {
      return isMafiaEvent;
    },
  },
  {
    description: 'attack to raid free.',
    methodName: 'attackRaid20',
    wait: 3,
    beforeFilter: function () {
      return ! isIdolEvent && ! isTowerEvent;
    },
  },
  // ↑ 自分のレイド ↑
  // ↓ クエスト ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
  },
  {
    description: 'go quest top.',
    methodName: 'goQuest',
    wait: 2,
    fail: {
      resetStep: true,
    }
  },
  // クエストのルーレット
  {
    description: 'quest item challenge',
    methodName: 'questItemChallenge',
    wait: 6,
  },
  // AP回復リクエスト一覧
  {
    description: 'ap recover request list.',
    methodName: 'apRecoverRequestList',
    wait: 2,
    beforeFilter: function () {
      return isMafiaEvent;
    },
  },
  // AP回復リクエスト受信
  {
    description: 'accept ap recover request',
    methodName: 'acceptApRecoverRequest',
    wait: 2,
    beforeFilter: function () {
      return isMafiaEvent;
    },
  },
  // 覇圏タブに行ってみる
  {
    description: 'go haken tab.',
    methodName: 'goQuestHakenTab',
    wait: 2,
    beforeFilter: function () {
      return (!isIdolEvent) && isHaken;
    },
  },
  {
    description: 'quest exec.',
    methodName: 'questExec',
    wait: 2,
    beforeFilter: function () {
      return (!isIdolEvent) && isHaken;
    },
  },
  {
    description: 'use haken ticket.',
    methodName: 'useHakenTicket',
    wait: 2,
    success: {
      skipSteps: 3
    },
    beforeFilter: function () {
      return (!isIdolEvent) && isHaken;
    },
  },
  // 覇圏が駄目な時のため期間限定タブに行ってみる
  {
    description: 'go gentei tab.',
    methodName: 'goQuestGenteiTab',
    wait: 2,
  },
  {
    description: 'quest exec.',
    methodName: 'questExec',
    wait: 2,
  },
  // ボスを殴ってみる
  {
    description: 'attack quest boss.',
    methodName: 'attackQuestBoss',
    wait: 2,
  },
  // AP回復リクエスト
  {
    description: 'send ap recover request',
    methodName: 'sendApRecoverRequest',
    wait: 2,
    beforeFilter: function () {
      return isMafiaEvent;
    },
  },
  // AP回復ボタン
  {
    description: 'ap recover',
    methodName: 'recoverAp',
    wait: 2,
  },
  // ↑ クエスト ↑
  // ↓ 摩天楼 ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'go duel tower',
    methodName: 'goTower',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'go select tower',
    methodName: 'goSelectTower',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
    fail: {
      skipSteps: 1
    },
  },
  {
    description: 'select tower',
    methodName: 'selectTower',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'go tower enemy list',
    methodName: 'goTowerEnemyList',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'recovery tower bp.',
    methodName: 'recoveryTowerBp',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'tower battle conf',
    methodName: 'towerBattleConf',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  {
    description: 'tower battle exec.',
    methodName: 'towerBattleExec',
    wait: 2,
    beforeFilter: function () {
      return isTowerEvent;
    },
  },
  // ↑ 摩天楼 ↑
  // ↓ ガチャ ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
  },
  {
    description: 'go gacha.',
    methodName: 'goGacha',
    wait: 3,
  },
  // 10000絆Pガチャ
  // {
  //   description: 'go gacha notmal tab.',
  //   methodName: 'goGachaNormalTab',
  //   wait: 3,
  // },
  // {
  //   description: 'draw 10000 kizuna p gacha.',
  //   methodName: 'drawKizunaGacha',
  //   wait: 3,
  // },
  // クエストガチャ
  {
    description: 'go gacha quest tab.',
    methodName: 'goGachaQuestTab',
    wait: 3,
    beforeFilter: function () {
      return isDrawRaidGacha;
    },
    fail: {
      skipSteps: 1
    }
  },
  {
    description: 'draw quest gacha.',
    methodName: 'drawQuestGacha',
    wait: 3,
    beforeFilter: function () {
      return isDrawRaidGacha;
    }
  },
  // ↑ ガチャ ↑
  // ↓ 新着情報 ↓
  {
    description: 'go to top.',
    methodName: 'jumpTop',
    wait: 2,
  },
  {
    description: 'move mypage.',
    methodName: 'goMypage',
    wait: 2,
  },
  // コインくじ
  {
    description: 'news lottery',
    methodName: 'goLottery',
    wait: 2,
    fail: {
      skipSteps: 1,
    }
  },
  {
    description: 'draw lottery',
    methodName: 'drawLottery',
    wait: 2,
    success: {
      resetStep: true,
    }
  },
  // 不良をぶっ飛ばす
  {
    description: 'go Grow',
    methodName: 'goGrow',
    wait: 2,
    fail: {
      skipSteps: 3,
    }
  },
  // アイテム使用confirm
  {
    description: 'confirm grow item',
    methodName: 'confirmGrowItem',
    wait: 2,
    fail: {
      skipSteps: 2,
    }
  },
  // アイテムを使う
  {
    description: 'use grow item',
    methodName: 'useGrowItem',
    wait: 2,
  },
  // バトル
  {
    description: 'grow battle',
    methodName: 'battleGrow',
    wait: 2,
  },
  // まりもの食材ルーレットをまとめて回す
  {
    description: 'collect kitchen items',
    methodName: 'collectKitchenItems',
    wait: 2,
    success: {
      resetStep: true,
    }
  },
  // 未受け取りレイド報酬
  {
    description: 'news raid reward',
    methodName: 'getRaidReward',
    wait: 2,
    success: {
      resetStep: true,
    }
  },
  // プレゼント受け取り
  {
    description: 'go present',
    methodName: 'goPresent',
    wait: 2,
    fail: {
      skipSteps: 1,
    }
  },
  {
    description: 'get present all',
    methodName: 'getPresentAll',
    wait: 2,
  },
  // まりもの食材ルーレットをまとめて回す
  {
    description: 'collect kitchen items',
    methodName: 'collectKitchenItems',
    wait: 2,
    success: {
      resetStep: true,
    }
  },
  // 抗争参戦を試みる
  {
    description: 'go active arena',
    methodName: 'goActiveArena',
    wait: 2,
    fail: {
      resetStep: true,
    },
    beforeFilter: function () {
      return isArena;
    }
  },
  // 抗争ページに行く
  {
    description: 'go arena',
    methodName: 'goArena',
    wait: 2,
    fail: {
      resetStep: true,
    },
    beforeFilter: function () {
      return isArena;
    }
  },
  // 奥義を発動
  {
    description: 'Execute Job',
    methodName: 'executeJob',
    wait: 2,
    fail: {
      resetStep: true,
    },
    beforeFilter: function () {
      return isArena;
    }
  },


];

const OPTION_METHODS = {
  setEnabled: function (request, sender, sendResponse) {
    if (request.isEnabled) {
      start(request.tabId);
    } else {
      stop();
    }

    let response = {msg: `setEnabled done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setRaidGacha: function (request, sender, sendResponse) {
    isDrawRaidGacha = request.isEnabled;

    let response = {msg: `setRaidGacha done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setIdolEvent: function (request, sender, sendResponse) {
    isIdolEvent = request.isEnabled;

    let response = {msg: `setIdolEvent done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setTowerEvent: function (request, sender, sendResponse) {
    isTowerEvent = request.isEnabled;

    let response = {msg: `setTowerEvent done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setMafiaEvent: function (request, sender, sendResponse) {
    isMafiaEvent = request.isEnabled;

    let response = {msg: `setMafiaEvent done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setIsHaken: function (request, sender, sendResponse) {
    isHaken = request.isEnabled;

    let response = {msg: `setIsHaken done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  },
  setIsArena: function (request, sender, sendResponse) {
    isArena = request.isEnabled;

    let response = {msg: `setIsArena done.: {${JSON.stringify(request)}}`};
    sendResponse(response);

    return true;
  }
};

const STORAGE_KEYS = {
  isEnabled: 'isEnabled',
  raidGacha: 'raidGacha',
  idolEvent: 'idolEvent',
  towerEvent: 'towerEvent',
  MafiaEvent: 'MafiaEvent',
  isHaken: 'isHaken',
  isArena: 'isArena',
};

var isRunning = false;
var isDrawRaidGacha = false;
var isIdolEvent = false;
var isTowerEvent = false;
var isMafiaEvent = false;
var isHaken = false;
var isArena = false;


function stop() {
  if (!isRunning) {
    return;
  }

  info("stop!");
  isRunning = false;
}

function start(tabId) {
  if (isRunning) {
    return;
  }

  info("start!");
  isRunning = true;

  execSequence(0, tabId);
}

function execSequence(index, tabId) {
  if (!isRunning) {
    return;
  }
  if (index >= SEQUENCES.length) {
    // 全部終わったらはじめに戻る
    execSequence(0, tabId);
    return;
  }

  let sequence = SEQUENCES[index];
  info(sequence['description'] + "[" + index + "]");

  // フィルターがあったら確認
  if (typeof sequence.beforeFilter !== 'undefined') {
    // スキップ
    if ( ! sequence.beforeFilter()) {
      info("skip this step by before filter.");
      execSequence(index + 1, tabId);
      return;
    }
  }

  // main.jsにメッセージを送る
    chrome.tabs.sendMessage(tabId, {
      methodName: sequence.methodName
    }, function(response) {
      // main.jsから処理完了通知がきたら次の処理を送る
      let nextIndex = index + 1;
      let nextAction = null;
      if (
        response
        && typeof response.result !== 'undefined'
        && response.result == false
      ) {
        if (typeof sequence.fail != 'undefined') {
          nextAction = sequence.fail;
        }
      }
      else {
        if (typeof sequence.success != 'undefined') {
          nextAction = sequence.success;
        }
      }

      if (nextAction) {
        // 処理をスキップ
        if (typeof nextAction.skipSteps != 'undefined') {
          info("skip steps [" + nextAction.skipSteps + "].");
          nextIndex += nextAction.skipSteps;
        }
        // 処理をはじめに戻す
        if (
          typeof nextAction.resetStep != 'undefined'
          && nextAction.resetStep
        ) {
          info("reset steps.");
          nextIndex = 0;
        }
      }

      setTimeout(execSequence.bind(this, nextIndex, tabId), sequence['wait'] * 1000);
    });

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

window.onload = function () {
  chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
    chrome.declarativeContent.onPageChanged.addRules([{
      conditions: [
        new chrome.declarativeContent.PageStateMatcher({
        pageUrl: {hostEquals: 'gang-trump.gree-pf.net'},
      }),
        new chrome.declarativeContent.PageStateMatcher({
        pageUrl: {hostEquals: 'g12024505.sp.pf.mbga.jp'},
      })
    ],
    actions: [new chrome.declarativeContent.ShowPageAction()]
    }]);
  });

  //メッセージリスナー
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    info("background.js message received. -> " + JSON.stringify(request));

    return OPTION_METHODS[request.methodName](request, sender, sendResponse);
  });

  // 設定読み込み
  chrome.storage.sync.get(STORAGE_KEYS.raidGacha, function(data) {
    isDrawRaidGacha = data[STORAGE_KEYS.raidGacha] ? true : false;
  });
  chrome.storage.sync.get(STORAGE_KEYS.idolEvent, function(data) {
    isIdolEvent = data[STORAGE_KEYS.idolEvent] ? true : false;
  });
  chrome.storage.sync.get(STORAGE_KEYS.towerEvent, function(data) {
    isTowerEvent = data[STORAGE_KEYS.towerEvent] ? true : false;
  });
  chrome.storage.sync.get(STORAGE_KEYS.mafiaEvent, function(data) {
    isMafiaEvent = data[STORAGE_KEYS.mafiaEvent] ? true : false;
  });
  chrome.storage.sync.get(STORAGE_KEYS.isHaken, function(data) {
    isHaken = data[STORAGE_KEYS.isHaken] ? true : false;
  });
  chrome.storage.sync.get(STORAGE_KEYS.isArena, function(data) {
    isArena = data[STORAGE_KEYS.isArena] ? true : false;
  });

  // はじめは無効にする
  chrome.storage.sync.set({[STORAGE_KEYS.isEnabled]: false}, function() {
    isRunning = false;
  });
}
