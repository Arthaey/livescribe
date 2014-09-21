require "htmlentities"
require "redcarpet"

renderer = Redcarpet::Render::HTML
markdown = Redcarpet::Markdown.new(renderer, extensions = {})
entities = HTMLEntities.new("html4")

input = $stdin.read

# Livescribe exports things like apostrophes as decimal entities.
input = entities.decode(input)

# Livescribe breaks on every line manually.
input.gsub!(/^<br>/, "")

# Livescribe doesn't preserve indented lines as new paragraphs.
input.gsub!(/\.\s*$\n^([A-Z])/m, ".\n\n\\1")

# Livescribe tends to surround asterisks with whitespace.
input.gsub!(/\*\s*(.+?)\s*\*/m, "*\\1*")

# Livescribe turns em-dashes into hyphens.
input.gsub!(/(^|\s+)-(\s+|$)/, " — ")

# Personal tweak: put smileys in <tt> tags.
input.gsub!(/(\s|\b)+([:;][)(P])(\s|\b)*/, " <tt>\\2</tt> ")
input.gsub!(/(\s|\b)+"([)(P])(\s|\b)*/, " <tt>:\\2</tt> ")

# Personal tweak: put "(?)" into superscripts.
input.gsub!(/(\s|\b)*C\?\)/, "<sup class='uncertain'>(?)</sup>")

# TODO: write a custom Redcarpet renderer for Livescribe output?
# http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html

output = markdown.render(input)
puts entities.decode(output)
