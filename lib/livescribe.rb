require "flickraw-cached"
require "htmlentities"
require "redcarpet"
require_relative "livescribe_renderer.rb"
require_relative "string.rb"
require_relative "settings.rb"

# TODO: move most of this class to the custom LivescribeRenderer?
class Livescribe
  attr_reader :allow_lists, :cc_email, :from_email, :url, :to_email

  FlickRaw.api_key = Settings["flickr_api_key"]
  FlickRaw.shared_secret = Settings["flickr_shared_secret"]

  @@entities = HTMLEntities.new
  @@renderer = Redcarpet::Markdown.new(LivescribeRenderer)

  def self.to_html!(input, hashtag_overrides = {})
    Livescribe.new(input, hashtag_overrides).to_html!
  end

  def initialize(input, hashtag_overrides = {})
    # By default, take email settings from the global settings.yml file.
    @from_email = nil
    @to_email = nil
    @cc_email = nil
    @url = nil

    # By default, treat input as full-fledged Markdown/HTML, which can contain
    # lists. However, some text (eg, prose) should treat all dashes as true
    # punctuation, not a list.
    @allow_lists = true

    # Normalize keys, for case-insensitive searching.
    @hashtag_overrides = {}
    hashtag_overrides.each_pair do |tag, overrides|
      @hashtag_overrides[tag.upcase] = overrides
    end

    # Livescribe exports things like apostrophes as decimal entities.
    input.force_encoding("UTF-8")
    @input = @@entities.decode(input)
  end

  def to_html!
    search_for_hashtag_overrides!
    remove_line_breaks!
    guess_new_paragraphs!
    remove_whitespace_around_asterisks!
    fix_quotation_marks!
    fix_dashes!
    wrap_smileys_in_tt!
    question_superscript!
    fix_parentheses!
    insert_flickr!

    output = @@renderer.render(to_s)
    @@entities.decode(output)
  end

  def to_s
    @input
  end

  # If the first line of input is a hashtag that matches the settings for
  # hashtag overrides, then remove the line and note the settings overrides.
  def search_for_hashtag_overrides!
    first = @input.lines.first
    if first =~ /^\s*#\s*(\w+)\s*$/ && @hashtag_overrides.has_key?($1.upcase)
      @hashtag_overrides[$1.upcase].each_pair do |key, val|
        instance_variable_set("@#{key}", val)
      end
      @input = @input.lines.to_a[1..-1].join
    end
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
  # And Livescribe does not understand angle quotation marks at all.
  def fix_quotation_marks!
    @input.gsub!(/''/, '"')
    @input.gsub!(/←\s*(.+?)\s*(?<![0-9])77(?![0-9])/m, "«\\1»")
  end

  # Livescribe turns em-dashes into hyphens.
  def fix_dashes!
    return @input unless @input.include?("-")

    is_list_item = false
    if @allow_lists
      # treat leading hyphens as list item bullets
      list_item_regex = /^\s*-\s*/m
      list_placeholder = "LIST_ITEM"

      if @input =~ list_item_regex
        is_list_item = true
        @input.gsub!(list_item_regex, list_placeholder)
      end
    end

    # find all obvious em-dashes (surrounded by spaces)
    @input.gsub!(/(\s+)-(\s+)/, " — ")

    # find somewhat-ambiguous em-dashes (em-dash plus a "detached hyphen")
    @input.gsub!(/\s*—\s*(.+?)\s*-(\s*|\b)/, " — \\1 — ")
    @input.gsub!(/(\s*|\b)-\s*(.+?)\s*—\s*/, " — \\2 — ")

    # find somewhat-ambiguous em-dashes (a pair of "detached hyphens")
    @input.gsub!(/\s+-(.+?)-\s+/, " — \\1 — ")

    if not @allow_lists
      # treat leading hyphens as leading em-dashes (eg, in Spanish dialog)
      @input.gsub!(/^\s*[-—]\s*/, "—")

      # treat "detached hyphens" as full em-dashes
      @input.gsub!(/(\S+?)-\s+(\S+?)/, "\\1 — \\2")
      @input.gsub!(/(\S+?)\s+-(\S+?)/, "\\1 — \\2")
    end

    if @allow_lists
      if is_list_item
        @input.gsub!(list_placeholder, " - ")
      end
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

  def insert_flickr!
    @input.scan(/#\s*Flickr\s*:\s*(\w+)/).each do |matches|
      short_id = matches.first
      begin
        photo = flickr.photos.getInfo(:photo_id => short_id)
        title = photo.title

        user_path = photo.owner.path_alias
        user_name = photo.owner.realname
        user_id = photo.owner.nsid
        url = FlickRaw.url_photopage(photo).sub(user_id, user_path)

        sizes = flickr.photos.getSizes(:photo_id => short_id)
        small_photo = sizes.find { |s| s["label"] == "Small" }
        width = small_photo["width"]
        height =  small_photo["height"]
        source = small_photo["source"]

        @input.sub!(/#\s*Flickr\s*:\s*#{short_id}/, <<-FLICKR.strip_heredoc

          <div class="photo">
            <a href="#{url}" title="#{title} by #{user_name}, on Flickr">
              <img src="#{source}" alt="#{title}" width="#{width}" height="#{height}">
              <br/>
              <span class="photo-title">#{title}</span>
            </a>
          </div>

        FLICKR
        )
      rescue FlickRaw::FailedResponse => e
        $stderr.puts "ERROR: public Flickr photo with short ID '#{short_id}' not found."
      end
    end
  end

end
