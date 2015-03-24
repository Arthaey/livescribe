require "flickraw-cached"
require "htmlentities"
require "redcarpet"
require_relative "Livescribe_renderer.rb"
require_relative "string.rb"
require_relative "settings.rb"

class Livescribe

  FlickRaw.api_key = Settings["flickr_api_key"]
  FlickRaw.shared_secret = Settings["flickr_shared_secret"]

  @@entities = HTMLEntities.new

  def self.to_html!(input)
    livescribe = Livescribe.new(input)
    livescribe.remove_line_breaks!
    livescribe.guess_new_paragraphs!
    livescribe.remove_whitespace_around_asterisks!
    livescribe.fix_quotation_marks!
    livescribe.fix_dashes!
    livescribe.wrap_smileys_in_tt!
    livescribe.question_superscript!
    livescribe.fix_parentheses!
    livescribe.insert_flickr!

    # TODO: move most of this class to the custom LivescribeRenderer?
    renderer = LivescribeRender
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
