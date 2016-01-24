# coding: utf-8

require 'date'
require_relative '../mae'
# ミリオンアーサー エクスタシス オートパイロット for Selenium + WebDriver
# # ブリテン共同戦線特化
module Mae_britain

  class Mae_britain < Mae::Mae

    def go_mypage
      self.move GAME_TOP_URL
      unless self.click_element('.btn-mypage')
        self.log('go to mypage fail.')
        @driver.close
      end
    end

    # マイページの情報を精査してやるべきことをする
    def do_action(count)
      result = false
      # result |= self.flash_knock # canvas ページにいるならノックして次に進む

      # N回に1回AP回復薬を買う
      if count % 50 == 49
        result |= self.buy_ap_portion
        self.go_mypage

        # 未受け取りギフトがあったら受け取る
        result |= self.receive_gift
        self.go_mypage
      end

      # レイド
      raid_result = self.raid_exec(@parameter_list['RAID_EXEC_COUNT'])
      result |= raid_result

      self.go_mypage

      # レイドを叩けていなかったら探索
      result |= self.quest_exec(@parameter_list['QUEST_EXEC_COUNT']) unless raid_result

    end

    def exec_quest_empty
      result = self.recovery_ap_exec
      # ダメだったらAP切れ
      self.set_expire(QUEST_EMPTY) unless result
      result
    end
    def raid_exec(limit)
      # return false if self.check_expire(RAID_EMPTY)
      count = 0
      # while count < limit && (self.help_raidboss_exec || self.own_raidboss_exec)
      while count < limit && (self.own_raidboss_exec)
        count += 1
      end
      count > 0
    end

  end #class
end #module
