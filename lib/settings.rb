require "settingslogic"

class Settings < Settingslogic
  source File.join(__dir__, "..", "settings.yml")
  load!
end
