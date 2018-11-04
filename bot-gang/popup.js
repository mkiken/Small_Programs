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
      chrome.storage.sync.set(
        {[OPTION_SETTINGS.isEnabled.storageKey]: isChecked}, function() { // HACK 無理やり変数をキーにしている
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
      chrome.storage.sync.set({[OPTION_SETTINGS.raidGacha.storageKey]: isChecked}, function() {
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
  // アイドル追っかけイベント
  idolEvent: {
    domId: 'idolEvent',
    storageKey: 'idolEvent',
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
      chrome.storage.sync.set({[OPTION_SETTINGS.idolEvent.storageKey]: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setIdolEvent',
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

  // 摩天楼イベント
  towerEvent: {
    domId: 'towerEvent',
    storageKey: 'towerEvent',
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
      chrome.storage.sync.set({[OPTION_SETTINGS.towerEvent.storageKey]: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setTowerEvent',
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

  // 覇権クエストを走るか
  isHaken: {
    domId: 'isHaken',
    storageKey: 'isHaken',
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
      chrome.storage.sync.set({[OPTION_SETTINGS.isHaken.storageKey]: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setIsHaken',
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

  // マフィアロワイヤル
  mafiaEvent: {
    domId: 'mafiaEvent',
    storageKey: 'mafiaEvent',
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
      chrome.storage.sync.set({[OPTION_SETTINGS.mafiaEvent.storageKey]: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setMafiaEvent',
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

  // 抗争関連の処理
  isArena: {
    domId: 'isArena',
    storageKey: 'isArena',
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
      chrome.storage.sync.set({[OPTION_SETTINGS.isArena.storageKey]: isChecked}, function() {
        console.log("is_checked is " + isChecked);
        chrome.runtime.sendMessage({
          methodName: 'setIsArena',
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
