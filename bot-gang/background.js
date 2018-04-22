const SEQUENCES = [
  // ↓ レイド救援 ↓
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 2,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 2,
  },
  {
    description: 'go raid list.',
    method_name: 'go_raid_list',
    wait: 2,
    fail: {
      skip_steps: 4
    }
  },
  {
    description: 'go raid help.',
    method_name: 'go_raid_help',
    wait: 2,
    fail: {
      skip_steps: 3
    }
  },
  {
    description: 'attack to raid.',
    method_name: 'attack_raid_free',
    wait: 3,
    success: {
      skip_step: 1,
    }
  },
  // 自分で殴る
  {
    description: 'attack to raid free.',
    method_name: 'attack_raid_20',
    wait: 3,
  },
  // ↑ レイド救援 ↑
  // ↓ 自分のレイド ↓
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 2,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 2,
  },
  {
    description: 'go own raid',
    method_name: 'go_own_raid',
    wait: 2,
    fail: {
      skip_steps: 3
    }
  },
  {
    description: 'attack to raid free.',
    method_name: 'attack_raid_free',
    wait: 3,
    success: {
      skip_steps: 2
    }
  },
  // 無料で殴れなかったら救援
  {
    description: 'request raid help',
    method_name: 'request_raid_help',
    wait: 3,
    success: {
      skip_steps: 1
    }
  },
  // 救援できなかったら自分で殴る
  {
    description: 'attack to raid free.',
    method_name: 'attack_raid_20',
    wait: 3,
  },
  // ↑ 自分のレイド ↑
  // ↓ クエスト ↓
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 2,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 2,
  },
  {
    description: 'go quest top.',
    method_name: 'go_quest',
    wait: 2,
    fail: {
      reset_step: true,
    }
  },
  // 覇圏タブに行ってみる
  {
    description: 'go haken tab.',
    method_name: 'go_quest_haken_tab',
    wait: 2,
    fail: {
      skip_steps: 5
    }
  },
  {
    description: 'quest exec.',
    method_name: 'quest_exec',
    wait: 2,
    fail: {
      skip_steps: 4
    }
  },
  // 覇圏が駄目な時のため期間限定タブに行ってみる
  {
    description: 'go gentei tab.',
    method_name: 'go_quest_gentei_tab',
    wait: 2,
    fail: {
      skip_steps: 3
    }
  },
  {
    description: 'quest exec.',
    method_name: 'quest_exec',
    wait: 2,
    success: {
      skip_steps: 2
    }
  },
  // ボスを殴ってみる
  {
    description: 'attack quest boss.',
    method_name: 'attack_quest_boss',
    wait: 2,
    success: {
      skip_steps: 1
    }
  },
  // クエストのルーレット
  {
    description: 'quest item challenge',
    method_name: 'quest_item_challenge',
    wait: 2,
  },
  // ↑ クエスト ↑
  // ↓ 10000絆Pガチャ ↓
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 2,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 2,
  },
  {
    description: 'go gacha.',
    method_name: 'go_gacha',
    wait: 3,
  },
  {
    description: 'go gacha notmal tab.',
    method_name: 'go_gacha_normal_tab',
    wait: 3,
  },
  {
    description: 'draw 10000 kizuna p gacha.',
    method_name: 'draw_10000_kizuna_gacha',
    wait: 3,
  },
  // ↑ 10000絆Pガチャ ↑
  // ↓ 新着情報 ↓
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 2,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 2,
  },
  // コインくじ
  {
    description: 'news lottery',
    method_name: 'go_lottery',
    wait: 2,
    fail: {
      skip_steps: 1,
    }
  },
  {
    description: 'draw lottery',
    method_name: 'draw_lottery',
    wait: 2,
    success: {
      reset_step: true,
    }
  },
  // 未受け取りレイド報酬
  {
    description: 'news raid reward',
    method_name: 'get_raid_reward',
    wait: 2,
    success: {
      reset_step: true,
    }
  },
  // プレゼント受け取り
  {
    description: 'go present',
    method_name: 'go_present',
    wait: 2,
    fail: {
      skip_steps: 1,
    }
  },
  {
    description: 'get present all',
    method_name: 'get_present_all',
    wait: 2,
  },
];

var isRunning = false;

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
  if (request.is_enabled) {
    start(request.tab_id);
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

  info("stop!");
  isRunning = false;
}

function start(tab_id) {
  if (isRunning) {
    return;
  }

  info("start!");
  isRunning = true;

  exec_sequence(0, tab_id);
}

function exec_sequence(index, tab_id) {
  if (!isRunning) {
    return;
  }
  if (index >= SEQUENCES.length) {
    // 全部終わったらはじめに戻る
    exec_sequence(0, tab_id);
    return;
  }

  let sequence = SEQUENCES[index];
  info("exec_sequence[" + index + "] (" + sequence['description'] + ")");

  // main.jsにメッセージを送る
    chrome.tabs.sendMessage(tab_id, {
      method_name: sequence.method_name
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
        if (typeof nextAction.skip_steps != 'undefined') {
          nextIndex += nextAction.skip_steps;
        }
        // 処理をはじめに戻す
        if (
          typeof nextAction.reset_step != 'undefined'
          && nextAction.reset_step
        ) {
          nextIndex = 0;
        }
      }

      setTimeout(exec_sequence.bind(this, nextIndex, tab_id), sequence['wait'] * 1000);
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
