const OPTION_SETTINGS = {
  // 有効か
  isEnabled: {
    domId: 'isEnabled',
    storageKey: 'is_enabled',
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
      chrome.storage.sync.set({is_enabled: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        // 現在開いているタブIDを送る
        chrome.tabs.query(
          { currentWindow: true, active: true },
          function (tabArray) {
            let currentTab = tabArray[0];
            chrome.runtime.sendMessage({
              method_name: 'setEnabled',
              is_enabled: isChecked,
              tab_id: currentTab.id
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
    storageKey: 'raid_gacha',
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
      chrome.storage.sync.set({is_enabled: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          method_name: 'setRaidGacha',
          is_enabled: isChecked,
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
