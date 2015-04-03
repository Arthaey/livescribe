require_relative "../lib/livescribe.rb"
require_relative "../lib/string.rb"

def expect_html(input, output)
  expect(Livescribe.to_html!(input)).to eq(output)
end

# TODO: test when there's more than one of each formatting thing in the input.
describe Livescribe do
  describe "#initialize" do
    it "uses input verbatim when it contains no entities" do
      expect_html("foo", "\n<p>foo</p>\n")
    end
    
    it "decodes hexidecimal entities" do
      expect_html("foo&#39;s", "\n<p>foo's</p>\n")
    end

    it "decodes decimal entities" do
      expect_html("foo&#x0027;s", "\n<p>foo's</p>\n")
    end

    it "decodes named entities" do
      expect_html("foo&apos;s", "\n<p>foo's</p>\n")
    end
  end

  describe "#search_for_hashtag_overrides!" do
    def expect_hashtag(input, output, expected)
      hashtags = {
        "MatchFound" => {
          "to_email" => "match@example.com",
        },
        "IgnoreMe" => {
          "to_email" => "ignored@example.com",
        },
      }
      livescribe = Livescribe.new(input, hashtags)
      expect(livescribe.to_html!).to eq(output)
      expect(livescribe.to_email).to eq(expected)
    end

    it "does nothing if the first line is not a hashtag" do
      expect_hashtag("#Heading\n\nfoo", "<h1>Heading</h1>\n\n<p>foo</p>\n", nil)
    end

    it "does nothing if hashtag does not have a match" do
      expect_hashtag("#NoMatch\n\nfoo", "<h1>NoMatch</h1>\n\n<p>foo</p>\n", nil)
    end

    it "sets the email delivery address if a match is found" do
      expect_hashtag("#MatchFound\n\nfoo", "\n<p>foo</p>\n", "match@example.com")
    end

    it "sets the email delivery address, even with extra whitespace" do
      expect_hashtag(" #  MatchFound \n\nfoo", "\n<p>foo</p>\n", "match@example.com")
    end

    it "matches are case-INsensitive" do
      expect_hashtag("#MATCHFOUND\n\nfoo", "\n<p>foo</p>\n", "match@example.com")
    end
  end

  describe "#remove_line_breaks!" do
    it "removes <br> elements that start a line" do
      expect_html("foo\n<br>bar", "\n<p>foo bar</p>\n")
    end

    it "leaves <br> elements that DO NOT start a line" do
      expect_html("foo\nbar<br>", "\n<p>foo bar<br></p>\n")
    end
  end

  describe "#guess_new_paragraphs!" do
    context "when the previous line ends with punctuation" do
      it "adds a break & keeps next alphabetic characters" do
        expect_html("foo.\nBar", "\n<p>foo.</p>\n\n<p>Bar</p>\n")
      end

      it "adds a break & keeps next non-alphabetic characters" do
        expect_html("foo.\n'Bar", "\n<p>foo.</p>\n\n<p>'Bar</p>\n")
      end
    end

    context "when it should NOT add a break" do
      it "ignores when the previous line does not end with punctuation" do
        expect_html("foo\nBar", "\n<p>foo Bar</p>\n")
      end

      it "ignores when the next line does not start with an uppercase letter" do
        expect_html("foo.\nbar", "\n<p>foo. bar</p>\n")
      end
    end
  end

  describe "#remove_extra_whitespace!" do
    it "removes consecutive whitespace" do
      expect_html("foo   bar", "\n<p>foo bar</p>\n")
    end
  end

  describe "#remove_whitespace_around_asterisks!" do
      it "removes spaces after the first asterisk" do
        expect_html("foo * bar* qux", "\n<p>foo <em>bar</em> qux</p>\n")
      end

      it "removes spaces before the second asterisk" do
        expect_html("foo *bar * qux", "\n<p>foo <em>bar</em> qux</p>\n")
      end

      it "removes spaces surrounding both asterisks" do
        expect_html("foo * bar * qux", "\n<p>foo <em>bar</em> qux</p>\n")
      end

      it "does nothing when there are no spaces" do
        expect_html("foo *bar* qux", "\n<p>foo <em>bar</em> qux</p>\n")
      end
  end

  describe "#fix_quotation_marks!" do
    it "replaces double apostrophes with a quotation mark" do
      expect_html("''foo''", "\n<p>\"foo\"</p>\n")
    end

    it "does nothing to single apostrophes" do
      expect_html("'foo'", "\n<p>'foo'</p>\n")
    end

    it "fixes misinterpreted angle quotation marks" do
        expect_html("←foo77", "\n<p>«foo»</p>\n")
        expect_html("← foo 77", "\n<p>«foo»</p>\n")
        expect_html("← foo\nbar 77", "\n<p>«foo bar»</p>\n")
    end

    it "ignores the number 77 when not a quotation mark" do
        expect_html("foo 77", "\n<p>foo 77</p>\n")
    end

    it "ignores a right arrow when not a quotation mark" do
        expect_html("← foo 777", "\n<p>← foo 777</p>\n")
    end
  end

  describe "#fix_dashes!" do
    it "does nothing when the dash isn't clearly an em-dash OR a list item" do
      expect_html("foo- bar", "\n<p>foo- bar</p>\n")
      expect_html("foo -bar", "\n<p>foo -bar</p>\n")
    end

    it "fixes obvious em-dashes" do
      expect_html("foo - bar", "\n<p>foo — bar</p>\n")
      expect_html("foo - bar - qux", "\n<p>foo — bar — qux</p>\n")
    end

    it "fixes somewhat ambiguous em-dashes" do
      expect_html("foo - bar- qux", "\n<p>foo — bar — qux</p>\n")
      expect_html("foo -bar - qux", "\n<p>foo — bar — qux</p>\n")
      expect_html("foo -bar- qux", "\n<p>foo — bar — qux</p>\n")
    end

    it "fixes list items that contain no other dashes" do
      expect_html("- foo", "<ul>\n<li>foo</li>\n</ul>\n")
      expect_html("- foo\n- bar", "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>\n")
      expect_html(" - foo\n - bar", "<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>\n")
    end

    it "fixes list items with em-dashes within them" do
      expect_html("- foo - bar", "<ul>\n<li>foo — bar</li>\n</ul>\n")
      expect_html("-foo - bar", "<ul>\n<li>foo — bar</li>\n</ul>\n")
    end

    it "fixes list items with hyphens within them" do
      expect_html("-foo-bar", "<ul>\n<li>foo-bar</li>\n</ul>\n")
    end

    it "fixes list items while ignoring ambiguous dashes" do
      expect_html("- foo- bar", "<ul>\n<li>foo- bar</li>\n</ul>\n")
      expect_html("- foo -bar", "<ul>\n<li>foo -bar</li>\n</ul>\n")
      expect_html("-foo- bar", "<ul>\n<li>foo- bar</li>\n</ul>\n")
      expect_html("-foo -bar", "<ul>\n<li>foo -bar</li>\n</ul>\n")
    end
  end

  describe "#fix_dashes! with no lists allowed" do
    def expect_html(input, output)
      overrides = {
        "NoLists" => { "allow_lists" => false }
      }
      livescribe = Livescribe.new("#NoLists\n#{input}", overrides)
      expect(livescribe.to_html!).to eq(output)
    end

    it "fixes even 'unclear' em-dashes" do
      expect_html("foo- bar", "\n<p>foo — bar</p>\n")
      expect_html("foo -bar", "\n<p>foo — bar</p>\n")
    end

    it "fixes obvious em-dashes" do
      expect_html("foo - bar", "\n<p>foo — bar</p>\n")
      expect_html("foo - bar - qux", "\n<p>foo — bar — qux</p>\n")
    end

    it "fixes somewhat ambiguous em-dashes" do
      expect_html("foo - bar- qux", "\n<p>foo — bar — qux</p>\n")
      expect_html("foo -bar - qux", "\n<p>foo — bar — qux</p>\n")
      expect_html("foo -bar- qux", "\n<p>foo — bar — qux</p>\n")
    end

    it "ignores possible list items that contain no other dashes" do
      expect_html("- foo", "\n<p>—foo</p>\n")
      expect_html("- foo\n- bar", "\n<p>—foo — bar</p>\n")
      expect_html(" - foo\n - bar", "\n<p>—foo — bar</p>\n")
    end

    it "ignores possible list items with em-dashes within them" do
      expect_html("- foo - bar", "\n<p>—foo — bar</p>\n")
      expect_html("-foo - bar", "\n<p>—foo — bar</p>\n")
    end

    it "ignores possible list items with hyphens within them" do
      expect_html("-foo-bar", "\n<p>—foo-bar</p>\n")
    end

    it "ignores possible list items while ignoring ambiguous dashes" do
      expect_html("- foo- bar", "\n<p>—foo — bar</p>\n")
      expect_html("- foo -bar", "\n<p>—foo — bar</p>\n")
      expect_html("-foo- bar", "\n<p>—foo — bar</p>\n")
      expect_html("-foo -bar", "\n<p>—foo — bar</p>\n")
    end
  end

  describe "#wrap_smileys_in_tt!" do
    context "when there are leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)" do
          expect_html("foo :)", "\n<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like :(" do
          expect_html("foo :(", "\n<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like :P" do
          expect_html("foo :P", "\n<p>foo <tt>:P</tt> </p>\n")
        end

        it "wraps smileys like ;)" do
          expect_html("foo ;)", "\n<p>foo <tt>;)</tt> </p>\n")
        end

        it "wraps smileys like ;(" do
          expect_html("foo ;(", "\n<p>foo <tt>;(</tt> </p>\n")
        end

        it "wraps smileys like ;P" do
          expect_html("foo ;P", "\n<p>foo <tt>;P</tt> </p>\n")
        end
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")" do
          expect_html("foo \")", "\n<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like \"(" do
          expect_html("foo \"(", "\n<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like \"P" do
          expect_html("foo \"P", "\n<p>foo <tt>:P</tt> </p>\n")
        end
      end
    end

    context "when there are NOT leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)" do
          expect_html("foo:)", "\n<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like :(" do
          expect_html("foo:(", "\n<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like :P" do
          expect_html("foo:P", "\n<p>foo <tt>:P</tt> </p>\n")
        end

        it "wraps smileys like ;)" do
          expect_html("foo;)", "\n<p>foo <tt>;)</tt> </p>\n")
        end

        it "wraps smileys like ;(" do
          expect_html("foo;(", "\n<p>foo <tt>;(</tt> </p>\n")
        end

        it "wraps smileys like ;P" do
          expect_html("foo;P", "\n<p>foo <tt>;P</tt> </p>\n")
        end
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")" do
          expect_html("foo\")", "\n<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like \"(" do
          expect_html("foo\"(", "\n<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like \"P" do
          expect_html("foo\"P", "\n<p>foo <tt>:P</tt> </p>\n")
        end
      end
    end
  end

  describe "#question_superscript!" do
    context "when there are leading spaces" do
      it "identifies leading parenthesis as (" do
        expect_html("foo (?)", "\n<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "identifies leading parenthesis as C" do
        expect_html("foo C?)", "\n<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "ignores other characters inside parentheses" do
        expect_html("foo (!)", "\n<p>foo (!)</p>\n")
      end
    end

    context "when there are NOT leading spaces" do
      it "identifies leading parenthesis as (" do
        expect_html("foo(?)", "\n<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "identifies leading parenthesis as C" do
        expect_html("fooC?)", "\n<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "ignores other characters inside parentheses" do
        expect_html("foo(!)", "\n<p>foo(!)</p>\n")
      end
    end
  end

  describe "#fix_parentheses" do
    it "fixes leading parenthesis identified as C" do
      expect_html("foo Cbar)", "\n<p>foo (bar)</p>\n")
    end

    it "does nothing to leading parenthesis identified as (" do
      expect_html("foo (bar)", "\n<p>foo (bar)</p>\n")
    end
  end

  describe "#insert_flickr" do

    expected_html = <<-FLICKR.strip_heredoc

        <div class="photo">
          <a href="https://www.flickr.com/photos/arthaey/15600859011" title="Shell prompt while working on my Livescribe script by Arthaey Angosii, on Flickr">
            <img src="https://farm6.staticflickr.com/5607/15600859011_fc8848a221_m.jpg" alt="Shell prompt while working on my Livescribe script" width="109" height="33">
            <br/>
            <span class="photo-title">Shell prompt while working on my Livescribe script</span>
          </a>
        </div>

    FLICKR

    it "links to an existing photo" do
      expect_html("#Flickr: pLAtRM", expected_html)
    end

    it "links to more than one existing photo"

    it "links to an existing photo, even with extra whitespace" do
      expect_html(" # Flickr : pLAtRM", expected_html)
    end

    it "does not crash when the photo is not found"
    it "does not crash when the photo is not public"
    it "does not crash when width and height cannot be determined"
    it "does not crash when API is not configured"
  end

  describe ".to_html" do
    it "does all supported conversions" do
      input =<<-END.strip_heredoc
        Hello * world*!
        <br>This is still the ← first 77 paragraph.
        <br>This is the   second paragraph, but ''Livescribe" doesn't
        <br>respect(?) paragraph indentations - alas.:)
      END

      output =<<-END.strip_heredoc

        <p>Hello <em>world</em>! This is still the «first» paragraph.</p>
        
        <p>This is the second paragraph, but "Livescribe" doesn't respect<sup class='uncertain'>(?)</sup> paragraph indentations — alas. <tt>:)</tt> </p>
      END

      expect_html(input, output)
    end
  end

end
