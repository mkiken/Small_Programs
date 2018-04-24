const SEQUENCES = [
  // ↓ レイド救援 ↓
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
    description: 'go raid list.',
    methodName: 'goRaidList',
    wait: 2,
    fail: {
      skipSteps: 4
    }
  },
  {
    description: 'go raid help.',
    methodName: 'goRaidHelp',
    wait: 2,
    fail: {
      skipSteps: 3
    }
  },
  {
    description: 'attack to raid.',
    methodName: 'attackRaidFree',
    wait: 3,
    success: {
      skip_step: 1,
    }
  },
  // 自分で殴る
  {
    description: 'attack to raid free.',
    methodName: 'attackRaid20',
    wait: 3,
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
      skipSteps: 3
    }
  },
  {
    description: 'attack to raid free.',
    methodName: 'attackRaidFree',
    wait: 3,
    success: {
      skipSteps: 2
    }
  },
  // 無料で殴れなかったら救援
  {
    description: 'request raid help',
    methodName: 'requestRaidHelp',
    wait: 3,
    success: {
      skipSteps: 1
    }
  },
  // 救援できなかったら自分で殴る
  {
    description: 'attack to raid free.',
    methodName: 'attackRaid20',
    wait: 3,
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
    wait: 2,
  },
  // 覇圏タブに行ってみる
  {
    description: 'go haken tab.',
    methodName: 'goQuestHakenTab',
    wait: 2,
  },
  {
    description: 'quest exec.',
    methodName: 'questExec',
    wait: 2,
    success: {
      skipSteps: 3
    }
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
  // ↑ クエスト ↑
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
  {
    description: 'go gacha notmal tab.',
    methodName: 'goGachaNormalTab',
    wait: 3,
  },
  {
    description: 'draw 10000 kizuna p gacha.',
    methodName: 'drawKizunaGacha',
    wait: 3,
    success: {
      skipSteps: 2
    }
  },
  // クエストガチャ
  {
    description: 'go gacha quest tab.',
    methodName: 'goGachaQuestTab',
    wait: 3,
    beforeFilter: function () {
      return isDrawRaidGacha;
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
  }
};

var isRunning = false;
var isDrawRaidGacha = false;

chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
  chrome.declarativeContent.onPageChanged.addRules([{
    conditions: [new chrome.declarativeContent.PageStateMatcher({
      pageUrl: {hostEquals: 'gang-trump.gree-pf.net'},
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
  info("execSequence[" + index + "] (" + sequence['description'] + ")");

  // フィルターがあったら確認
  if (typeof sequence.beforeFilter !== 'undefined') {
    // スキップ
    if ( ! sequence.beforeFilter()) {
      execSequence(index + 1, tabId);
      return;
    }
  }

  // main.jsにメッセージを送る
    chrome.tabs.sendMessage(tabId, {
      methodName: sequence.methodName
    }, function(response) {
      // main.jsから処理完了通知がきたら次の処理を送る
      info("response receive. " + JSON.stringify(response));
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
          nextIndex += nextAction.skipSteps;
        }
        // 処理をはじめに戻す
        if (
          typeof nextAction.resetStep != 'undefined'
          && nextAction.resetStep
        ) {
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
