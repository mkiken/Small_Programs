#ruby:"mae_mobage_run.rb"

module Mae_mobage_run

  require_relative '../mae_run'
  require_relative './mae_mobage'
  include Mae_run

  def main
    config          = YAML::load_file(File.join(__dir__, 'config_mobage.yml'))
    mobage_id       = config['mobage_id']
    mobage_password = config['mobage_password']
    quest_type      = config['quest_type']
    max_count       = config['max_count']
    self.exec(mobage_id, mobage_password, quest_type, max_count, 1)
  end

  def self.exec(mobage_id, mobage_password, quest_type, max_count, count)
    return false if count >= max_count

    begin
      driver        = Mae_run.get_chrome_driver
      mae           = Mae_mobage::Mae_mobage.new
      Mae_run.extend_logging mae
      mae.log "#{count}th game start."
      mae.setting(driver, mobage_id, mobage_password, 10000000, quest_type)
      mae.play
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
      self.exec(mobage_id, mobage_password, quest_type, max_count, count + 1)
    end
  end

  module_function :main

end
