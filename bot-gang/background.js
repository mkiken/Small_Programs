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
  },
  {
    description: 'go raid help.',
    method_name: 'go_raid_help',
    wait: 2,
  },
  {
    description: 'attack to raid.',
    method_name: 'attack_raid',
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
  },
  {
    description: 'attack to raid.',
    method_name: 'attack_raid',
    wait: 3,
  },
  {
    description: 'request raid help',
    method_name: 'request_raid_help',
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
  },
  // 覇圏タブに行ってみる
  {
    description: 'go haken tab.',
    method_name: 'go_quest_haken_tab',
    wait: 2,
  },
  {
    description: 'quest exec.',
    method_name: 'quest_exec',
    wait: 2,
  },
  // 覇圏が駄目な時のため期間限定タブに行ってみる
  {
    description: 'go gentei tab.',
    method_name: 'go_quest_gentei_tab',
    wait: 2,
  },
  {
    description: 'quest exec.',
    method_name: 'quest_exec',
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
      setTimeout(exec_sequence.bind(this, index + 1, tab_id), sequence['wait'] * 1000);
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
