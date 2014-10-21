require_relative "lib/livescribe.rb"

input = $stdin.read
puts Livescribe.to_markdown(input)
