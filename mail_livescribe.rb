require "mail"
require "pony"
require_relative "lib/livescribe.rb"
require_relative "lib/settings.rb"

input = $stdin.read
output = Livescribe.to_html(input)

mail_options = {
  :from      => Settings.from_email,
  :to        => Settings.to_email,
  :cc        => Settings.cc_email,
  :html_body => output,
  :via       => :sendmail
}

debug_msg = "Email sent to #{Settings.to_email}"
if Settings["cc_email"]
  mail_options[:cc] = Settings.cc_email
  debug_msg += " and CC'd to #{Settings.cc_email}"
end

Pony.mail(mail_options)
puts debug_msg
