require "pony"
require "yaml"
require_relative "lib/livescribe.rb"

SETTINGS_FILE = "settings.yml"

if !File.exist?(SETTINGS_FILE)
  abort "ERROR: Could not find settings file '#{SETTINGS_FILE}'."
end

settings = YAML.load_file(SETTINGS_FILE)

input = $stdin.read
output = Livescribe.to_html(input)

Pony.mail(
  :to        => settings["email"]["to"],
  :from      => settings["email"]["from"],
  :html_body => output,
  :via       => :sendmail
)

puts "Email sent to #{settings["email"]["to"]}."
