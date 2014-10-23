require_relative "../lib/livescribe.rb"
require_relative "../lib/string.rb"

def expect_html(input, output)
  expect(Livescribe.to_html(input)).to eq(output)
end

# TODO: test when there's more than one of each formatting thing in the input.
describe Livescribe do
  describe "#initialize" do
    it "uses input verbatim when it contains no entities" do
      expect_html("foo", "<p>foo</p>\n")
    end
    
    it "decodes hexidecimal entities" do
      expect_html("foo&#39;s", "<p>foo's</p>\n")
    end

    it "decodes decimal entities" do
      expect_html("foo&#x0027;s", "<p>foo's</p>\n")
    end

    it "decodes named entities" do
      expect_html("foo&apos;s", "<p>foo's</p>\n")
    end
  end

  describe "#remove_line_breaks!" do
    it "removes <br> elements that start a line" do
      expect_html("foo\n<br>bar", "<p>foo\nbar</p>\n")
    end

    it "leaves <br> elements that DO NOT start a line" do
      expect_html("foo\nbar<br>", "<p>foo\nbar<br></p>\n")
    end
  end

  describe "#guess_new_paragraphs!" do
    context "when the previous line ends with punctuation" do
      it "adds a break & keeps next alphabetic characters" do
        expect_html("foo.\nBar", "<p>foo.</p>\n\n<p>Bar</p>\n")
      end

      it "adds a break & keeps next non-alphabetic characters" do
        expect_html("foo.\n'Bar", "<p>foo.</p>\n\n<p>'Bar</p>\n")
      end
    end

    context "when it should NOT add a break" do
      it "ignores when the previous line does not end with punctuation" do
        expect_html("foo\nBar", "<p>foo\nBar</p>\n")
      end

      it "ignores when the next line does not start with an uppercase letter" do
        expect_html("foo.\nbar", "<p>foo.\nbar</p>\n")
      end
    end
  end

  describe "#remove_whitespace_around_asterisks!" do
      it "removes spaces after the first asterisk" do
        expect_html("foo * bar* qux", "<p>foo <em>bar</em> qux</p>\n")
      end

      it "removes spaces before the second asterisk" do
        expect_html("foo *bar * qux", "<p>foo <em>bar</em> qux</p>\n")
      end

      it "removes spaces surrounding both asterisks" do
        expect_html("foo * bar * qux", "<p>foo <em>bar</em> qux</p>\n")
      end

      it "does nothing when there are no spaces" do
        expect_html("foo *bar* qux", "<p>foo <em>bar</em> qux</p>\n")
      end
  end

  describe "#fix_quotation_marks!" do
    it "replaces double apostrophes with a quotation mark" do
      expect_html("''foo''", "<p>\"foo\"</p>\n")
    end

    it "does nothing to single apostrophes" do
      expect_html("'foo'", "<p>'foo'</p>\n")
    end
  end

  describe "#fix_dashes!" do
    it "does nothing when the dash isn't clearly an em-dash OR a list item" do
      expect_html("foo- bar", "<p>foo- bar</p>\n")
      expect_html("foo -bar", "<p>foo -bar</p>\n")
    end

    it "fixes obvious em-dashes" do
      expect_html("foo - bar", "<p>foo — bar</p>\n")
      expect_html("foo - bar - qux", "<p>foo — bar — qux</p>\n")
    end

    it "fixes somewhat ambiguous em-dashes" do
      expect_html("foo - bar- qux", "<p>foo — bar — qux</p>\n")
      expect_html("foo -bar - qux", "<p>foo — bar — qux</p>\n")
      expect_html("foo -bar- qux", "<p>foo — bar — qux</p>\n")
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

  describe "#wrap_smileys_in_tt!" do
    context "when there are leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)" do
          expect_html("foo :)", "<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like :(" do
          expect_html("foo :(", "<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like :P" do
          expect_html("foo :P", "<p>foo <tt>:P</tt> </p>\n")
        end

        it "wraps smileys like ;)" do
          expect_html("foo ;)", "<p>foo <tt>;)</tt> </p>\n")
        end

        it "wraps smileys like ;(" do
          expect_html("foo ;(", "<p>foo <tt>;(</tt> </p>\n")
        end

        it "wraps smileys like ;P" do
          expect_html("foo ;P", "<p>foo <tt>;P</tt> </p>\n")
        end
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")" do
          expect_html("foo \")", "<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like \"(" do
          expect_html("foo \"(", "<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like \"P" do
          expect_html("foo \"P", "<p>foo <tt>:P</tt> </p>\n")
        end
      end
    end

    context "when there are NOT leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)" do
          expect_html("foo:)", "<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like :(" do
          expect_html("foo:(", "<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like :P" do
          expect_html("foo:P", "<p>foo <tt>:P</tt> </p>\n")
        end

        it "wraps smileys like ;)" do
          expect_html("foo;)", "<p>foo <tt>;)</tt> </p>\n")
        end

        it "wraps smileys like ;(" do
          expect_html("foo;(", "<p>foo <tt>;(</tt> </p>\n")
        end

        it "wraps smileys like ;P" do
          expect_html("foo;P", "<p>foo <tt>;P</tt> </p>\n")
        end
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")" do
          expect_html("foo\")", "<p>foo <tt>:)</tt> </p>\n")
        end

        it "wraps smileys like \"(" do
          expect_html("foo\"(", "<p>foo <tt>:(</tt> </p>\n")
        end

        it "wraps smileys like \"P" do
          expect_html("foo\"P", "<p>foo <tt>:P</tt> </p>\n")
        end
      end
    end
  end

  describe "#question_superscript!" do
    context "when there are leading spaces" do
      it "identifies leading parenthesis as (" do
        expect_html("foo (?)", "<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "identifies leading parenthesis as C" do
        expect_html("foo C?)", "<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "ignores other characters inside parentheses" do
        expect_html("foo (!)", "<p>foo (!)</p>\n")
      end
    end

    context "when there are NOT leading spaces" do
      it "identifies leading parenthesis as (" do
        expect_html("foo(?)", "<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "identifies leading parenthesis as C" do
        expect_html("fooC?)", "<p>foo<sup class='uncertain'>(?)</sup></p>\n")
      end

      it "ignores other characters inside parentheses" do
        expect_html("foo(!)", "<p>foo(!)</p>\n")
      end
    end
  end

  describe "#fix_parentheses" do
    it "fixes leading parenthesis identified as C" do
      expect_html("foo Cbar)", "<p>foo (bar)</p>\n")
    end

    it "does nothing to leading parenthesis identified as (" do
      expect_html("foo (bar)", "<p>foo (bar)</p>\n")
    end
  end

  describe "#insert_flickr" do
    it "links to existing photos" do
      expect_html("#Flickr: pLAtRM", <<-FLICKR.unindent
        <div class="photo">
          <a href="https://www.flickr.com/photos/arthaey/15600859011" title="Shell prompt while working on my Livescribe script by Arthaey Angosii, on Flickr">
            <img src="https://farm6.staticflickr.com/5607/15600859011_fc8848a221_m.jpg" alt="Shell prompt while working on my Livescribe script" width="109" height="33">
            <br/>
            <span class="photo-title">Shell prompt while working on my Livescribe script</span>
          </a>
        </div>
      FLICKR
      )
    end
  end

  describe ".to_html" do
    it "does all supported conversions" do
      input =<<-END.unindent
        Hello * world*!
        <br>This is still the first paragraph.
        <br>This is the second paragraph, but ''Livescribe" doesn't
        <br>respect(?) paragraph indentations - alas.:)
      END

      output =<<-END.unindent
        <p>Hello <em>world</em>!
        This is still the first paragraph.</p>
        
        <p>This is the second paragraph, but "Livescribe" doesn't
        respect<sup class='uncertain'>(?)</sup> paragraph indentations — alas. <tt>:)</tt> </p>
      END

      expect_html(input, output)
    end
  end

end
