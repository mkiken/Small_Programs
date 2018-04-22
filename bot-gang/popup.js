const OPTION_SETTINGS = {
  // 有効か
  isEnabled: {
    domId: 'isEnabled',
    storageKey: 'isEnabled',
    dom: null,
    setDom: function () {
      this.dom = document.getElementById(this.domId);
    },
    setOption: function () {
      let that = this;
      chrome.storage.sync.get(that.storageKey, function(data) {
        that.dom.checked = data[that.storageKey] ? true : false;
      });
    },
    onClick: function () {
      let isChecked = this.checked;
      chrome.storage.sync.set({isEnabled: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        // 現在開いているタブIDを送る
        chrome.tabs.query(
          { currentWindow: true, active: true },
          function (tabArray) {
            let currentTab = tabArray[0];
            chrome.runtime.sendMessage({
              methodName: 'setEnabled',
              isEnabled: isChecked,
              tabId: currentTab.id
            },
            function(response) {
              console.log(response);
            });
          }
        );
      });
    },
    setEventListener: function () {
      this.dom.addEventListener('click', this.onClick);
    }
  },
  // レイドガチャを引くか
  raidGacha: {
    domId: 'raidGacha',
    storageKey: 'raidGacha',
    dom: null,
    setDom: function () {
      this.dom = document.getElementById(this.domId);
    },
    setOption: function () {
      let that = this;
      chrome.storage.sync.get(that.storageKey, function(data) {
        that.dom.checked = data[that.storageKey] ? true : false;
      });
    },
    onClick: function () {
      let isChecked = this.checked;
      chrome.storage.sync.set({isEnabled: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setRaidGacha',
          isEnabled: isChecked,
        },
        function(response) {
          console.log(response);
        });
      });
    },
    setEventListener: function () {
      console.log(this);
      this.dom.addEventListener('click', this.onClick);
    }
  },
};

window.onload = function () {
  for (key in OPTION_SETTINGS) {
    let value = OPTION_SETTINGS[key];
    value.setDom();
    value.setOption();
    value.setEventListener();
  }
}
