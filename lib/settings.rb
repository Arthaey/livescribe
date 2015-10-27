require "settingslogic"

class Settings < Settingslogic
  source File.join(__dir__, "..", "settings.yml")
  load!

  def self.inspect
    copy = to_hash()
    copy.each_pair { |k,v| copy[k] = "[censored]" if k =~ /secret|password/ }.inspect
  end
end
