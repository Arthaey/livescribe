require "redcarpet"

# http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html

class LivescribeRenderer < Redcarpet::Render::HTML

  def initialize(render_options = {})
    super({:xhtml => true}.merge(render_options))
  end

  # I prefer an extra newline between my block elements.
  def block_html(raw_html)
    "\n#{raw_html}"
  end

  # Remove superfluous newlines *within* a paragraph.
  def paragraph(text)
    text.gsub!(/\n/, " ")
    "\n<p>#{text}</p>\n"
  end

end
