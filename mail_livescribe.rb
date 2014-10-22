require "mail"
require "optparse"
require "pony"
require_relative "lib/livescribe.rb"
require_relative "lib/settings.rb"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("-d", "--[no-]dry-run", "Do not really send email") { |x| options[:dry_run] = x }
  opts.on("-v", "--[no-]verbose", "Show verbose information") { |x| options[:verbose] = x }
  opts.on("-p", "--[no-]print", "Print converted input")      { |x| options[:print]   = x }
  opts.on("-e", "--[no-]email-input", "Input is a forwarded email") do
    options[:email_input] = x
  end
end.parse!

input = $stdin.read
if options[:email_input]
  input = Mail.new(input).body.decoded
end

output = Livescribe.to_html(input)
puts output if options[:print]

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

Pony.mail(mail_options) unless options[:dry_run]
puts debug_msg if options[:verbose]
