const checkBoxIsEnabled = document.getElementById('isEnabled');

chrome.storage.sync.get('is_enabled', function(data) {
  checkBoxIsEnabled.checked = data.is_enabled ? true : false;
});

function onClickCheckBox() {
  let isChecked = this.checked;
  chrome.storage.sync.set({is_enabled: isChecked}, function() {
    console.log("is_checked is " + isChecked);
    // 現在開いているタブIDを送る
    chrome.tabs.query(
        { currentWindow: true, active: true },
        function (tabArray) {
          let currentTab = tabArray[0];
          chrome.runtime.sendMessage({
            is_enabled: isChecked,
            tab_id: currentTab.id
          },
          function(response) {
            console.log(response);
          });
        }
    );
  });
}

checkBoxIsEnabled.addEventListener('click', onClickCheckBox)
