require "htmlentities"
require "redcarpet"

class Livescribe

  @@entities = HTMLEntities.new("html4")

  def self.to_markdown(input)
    livescribe = Livescribe.new(input)
    livescribe.remove_line_breaks!
    livescribe.guess_new_paragraphs!
    livescribe.remove_whitespace_around_asterisks!
    livescribe.fix_quotation_marks!
    livescribe.fix_em_dashes!
    livescribe.wrap_smilies_in_tt!
    livescribe.question_superscript!

    # TODO: write a custom Redcarpet renderer for Livescribe output?
    # http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html

    renderer = Redcarpet::Render::HTML
    redcarpet = Redcarpet::Markdown.new(renderer)
    output = redcarpet.render(livescribe.to_s)

    @@entities.decode(output)
  end

  def initialize(input)
    # Livescribe exports things like apostrophes as decimal entities.
    @input = @@entities.decode(input)
  end

  def to_s
    @input
  end

  def remove_line_breaks!
    # Livescribe breaks on every line manually.
    @input.gsub!(/^<br>/, "")
  end

  def guess_new_paragraphs!
    # Livescribe doesn't preserve indented lines as new paragraphs.
    @input.gsub!(/\.\s*$\n^([A-Z])/m, ".\n\n\\1")
  end

  def remove_whitespace_around_asterisks!
    # Livescribe tends to surround asterisks with whitespace.
    @input.gsub!(/\*\s*(.+?)\s*\*/m, "*\\1*")
  end

  def fix_quotation_marks!
    # Livescribe sometimes thinks a quotation mark is two apostrophes.
    @input.gsub!(/''/, '"')
  end

  def fix_em_dashes!
    # Livescribe turns em-dashes into hyphens.
    @input.gsub!(/(^|\s+)-(\s+|$)/, " — ")
  end

  def wrap_smilies_in_tt!
    # Personal tweak: put smileys in <tt> tags.
    @input.gsub!(/(\s|\b)+([:;][)(P])(\s|\b)*/, " <tt>\\2</tt> ")
    @input.gsub!(/(\s|\b)+"([)(P])(\s|\b)*/, " <tt>:\\2</tt> ")
  end

  def question_superscript!
    # Personal tweak: put "(?)" into superscripts.
    @input.gsub!(/(\s|\b)*C\?\)/, "<sup class='uncertain'>(?)</sup>")
  end
end
