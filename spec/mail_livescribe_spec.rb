describe "convert script" do
  it "converts input from a file"
  it "converts input from STDIN"
end

describe "command-line options" do
  it "gracefully handles unknown options"
  it "--dry-run does not send an email"
  it "--no-dry-run does send an email "
  it "--verbose shows verbose information"
  it "--no-verbose does not verbose information"
  it "--print displays converted input"
  it "--no-print does not display converted input"
  it "--email-input handles email headers"
  it "--no-email-input takes input verbatim"
end

describe "config file options" do
  it "from_email default value"
  it "to_email default value"
  it "cc_email default value"
  it "hashtag_overrides overrides settings"
end

describe "command-line values override config file" do
  it "--from overrides from_email"
  it "--to overrides to_email"
  it "--cc overrides cc_email"
end
