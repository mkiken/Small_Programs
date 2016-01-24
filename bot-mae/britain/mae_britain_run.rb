#ruby:"mae_britain_run.rb"

module Mae_britain_run

  require_relative '../mae_run'
  require_relative './mae_britain'
  include Mae_run


  def self.exec(gree_id, gree_password, quest_type, max_count, count)
    return false if count >= max_count

    begin
      driver        = Mae_run.get_chrome_driver
      mae           = Mae_britain::Mae_britain.new
      Mae_run.extend_logging mae
      mae.log "#{count}th game start."
      mae.setting(driver, gree_id, gree_password, 10000000, quest_type, FALSE)
      mae.play 1
    rescue => ex
      p ex

      # driver.closeに失敗することがあるので、念のためbeginで囲っておく
      begin
        # 終了時にドライバーを閉じる
        driver.close
      rescue => e
        p e
      end
      # ドライバーが閉じるように一応30秒待つ
      sleep 30
      self.exec(gree_id, gree_password, quest_type, max_count, count + 1)
    end
  end

  module_function :main

end
