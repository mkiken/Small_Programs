const SEQUENCES = [
  {
    description: 'go to top.',
    method_name: 'jump_top',
    wait: 3,
  },
  {
    description: 'move mypage.',
    method_name: 'go_mypage',
    wait: 3,
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
  if (index >= SEQUENCES.length) {
    return;
  }

  let sequence = SEQUENCES[index];
  info("exec_sequence[" + index + "] (" + sequence['description'] + ")");

  // main.jsにメッセージを送る
    chrome.tabs.sendMessage(tab_id, {
      method_name: sequence.method_name
    }, function(response) {
    });
  setTimeout(exec_sequence.bind(this, index + 1, tab_id), sequence['wait'] * 1000);

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
