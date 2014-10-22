require "settingslogic"

class Settings < Settingslogic
  source "settings.yml"
  load!
end
