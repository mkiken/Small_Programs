chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
  chrome.declarativeContent.onPageChanged.addRules([{
    conditions: [new chrome.declarativeContent.PageStateMatcher({
      pageUrl: {hostEquals: 'gang-trump.gree-pf.net'},
    })
    ],
        actions: [new chrome.declarativeContent.ShowPageAction()]
  }]);
});
