require "htmlentities"
require "redcarpet"

class Livescribe

  @@entities = HTMLEntities.new

  def self.to_html(input)
    livescribe = Livescribe.new(input)
    livescribe.remove_line_breaks!
    livescribe.guess_new_paragraphs!
    livescribe.remove_whitespace_around_asterisks!
    livescribe.fix_quotation_marks!
    livescribe.fix_dashes!
    livescribe.wrap_smileys_in_tt!
    livescribe.question_superscript!
    livescribe.fix_parentheses!

    # TODO: write a custom Redcarpet renderer for Livescribe output?
    # http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html

    renderer = Redcarpet::Render::HTML
    redcarpet = Redcarpet::Markdown.new(renderer)
    output = redcarpet.render(livescribe.to_s)

    @@entities.decode(output)
  end

  def initialize(input)
    # Livescribe exports things like apostrophes as decimal entities.
    input.force_encoding("UTF-8")
    @input = @@entities.decode(input)
  end

  def to_s
    @input
  end

  # Livescribe breaks on every line manually.
  def remove_line_breaks!
    @input.gsub!(/^<br>/, "")
  end

  # Livescribe doesn't preserve indented lines as new paragraphs.
  def guess_new_paragraphs!
    @input.gsub!(/\.\s*$\n^([[:punct:][:upper:]])/m, ".\n\n\\1")
  end

  # Livescribe tends to surround asterisks with whitespace.
  def remove_whitespace_around_asterisks!
    @input.gsub!(/\*\s*(.+?)\s*\*/m, "*\\1*")
  end

  # Livescribe sometimes thinks a quotation mark is two apostrophes.
  def fix_quotation_marks!
    @input.gsub!(/''/, '"')
  end

  # Livescribe turns em-dashes into hyphens.
  def fix_dashes!
    return @input unless @input.include?("-")

    is_list_item = false
    list_item_regex = /^\s*-\s*/m
    list_placeholder = "LIST_ITEM"

    if @input =~ list_item_regex
      is_list_item = true
      @input.gsub!(list_item_regex, list_placeholder)
    end

    # find all obvious em-dashes (surrounded by spaces)
    @input.gsub!(/(\s+)-(\s+)/, " — ")

    # find somewhat-ambiguous em-dashes (em-dash plus a "detached hyphen")
    @input.gsub!(/\s*—\s*(.+?)\s*-(\s*|\b)/, " — \\1 — ")
    @input.gsub!(/(\s*|\b)-\s*(.+?)\s*—\s*/, " — \\2 — ")

    # find somewhat-ambiguous em-dashes (a pair of "detached hyphens")
    @input.gsub!(/\s+-(.+?)-\s+/, " — \\1 — ")

    if is_list_item
      @input.gsub!(list_placeholder, " - ")
    end
  end

  # Personal tweak: put smileys in <tt> tags.
  def wrap_smileys_in_tt!
    @input.gsub!(/([[:punct:]])?(\s*|\b)([:;][)(P])(\s*|\b)/, "\\1 <tt>\\3</tt> ")
    @input.gsub!(/([[:punct:]])?(\s*|\b)"([)(P])(\s*|\b)/, "\\1 <tt>:\\3</tt> ")
  end

  # Personal tweak: put "(?)" into superscripts.
  def question_superscript!
    @input.gsub!(/(\s|\b)*[C(]\?\)/, "<sup class='uncertain'>(?)</sup>")
  end

  # Livescribe sometimes turns leading parentheses into C's.
  def fix_parentheses!
    @input.gsub!(/C([^)]+?)\)/, "(\\1)")
  end
end
