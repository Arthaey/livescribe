require "logger"
require "mail"
require "optparse"
require_relative "lib/livescribe.rb"
require_relative "lib/settings.rb"

log_file = File.new(Settings.log, File::WRONLY | File::APPEND)
logger = Logger.new(log_file)
logger.level = Logger::DEBUG
logger.info("=" * 50)
logger.info("Starting mail_livescribe.rb script.")

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("-d", "--[no-]dry-run", "Do not really send email") { |x| options[:dry_run] = x }
  opts.on("-v", "--[no-]verbose", "Show verbose information") { |x| options[:verbose] = x }
  opts.on("-p", "--[no-]print", "Print converted input")      { |x| options[:print]   = x }
  opts.on("-e", "--[no-]email-input", "Input is a forwarded email") do |x|
    options[:email_input] = x
  end

  # Override values in settings.yml
  opts.on("-t", "--[no-]to EMAIL", "To: email address")       { |x| options[:to]      = x }
  opts.on("-c", "--[no-]cc EMAIL", "Cc: email address")       { |x| options[:cc]      = x }
  opts.on("-f", "--[no-]from EMAIL", "From: email address")   { |x| options[:from]    = x }
end.parse!
logger.info("Options: #{options.inspect}")

input = $stdin.read
if options[:email_input]
  input = Mail.new(input).body.decoded
end
logger.debug("Input:\n#{input}")

livescribe = Livescribe.new(input, Settings.hashtag_deliveries)
output = livescribe.to_html!
puts output if options[:print]
logger.debug("Output:\n#{output}")

from_email = options[:from] || Settings.from_email
to_email = options[:to] || livescribe.hashtag_delivery || Settings.to_email
cc_email = options[:cc] || Settings["cc_email"]

mail = Mail.new do
  from from_email
  to to_email

  html_part do
    content_type "text/html; charset=UTF-8"
    body output
  end
end

debug_msg = "Email sent to #{to_email}"
if cc_email
  mail[:cc] = cc_email
  debug_msg += " and CC'd to #{cc_email}"
end

logger.debug("Email:\n#{mail.inspect}")
if options[:dry_run]
  debug_msg += " [DRY RUN]"
else
  mail.delivery_method(:sendmail)
  mail.deliver
end

puts debug_msg if options[:verbose]
logger.info(debug_msg)

logger.info("Done")
logger.info("=" * 40)
logger.close
