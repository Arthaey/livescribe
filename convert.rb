require "htmlentities"
require "redcarpet"

renderer = Redcarpet::Render::HTML
markdown = Redcarpet::Markdown.new(renderer, extensions = {})
entities = HTMLEntities.new("html4")

input = $stdin.read

# TODO: write a custom Redcarpet renderer for Livescribe output?
# http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html

# Livescribe-specific cleanup, to make it parsable as Markdown.
input = entities.decode(input)
input.gsub!(/^<br>/, "")
input.gsub!(/\.\s*$\n^([A-Z])/, ".\n\n\\1")

# Personal tweak: put smileys in <tt> tags.
input.gsub!(/(\s|\b)+([:;][)(P])(\s|\b)*/, "\\1<tt>\\2</tt>\\3")

output = markdown.render(input)
puts entities.decode(output)
