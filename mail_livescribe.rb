require "pony"
require_relative "lib/livescribe.rb"
require_relative "lib/settings.rb"

input = $stdin.read
output = Livescribe.to_html(input)

Pony.mail(
  :to        => Settings.to_email,
  :from      => Settings.from_email,
  :html_body => output,
  :via       => :sendmail
)

puts "Email sent to #{Settings.to_email}."
