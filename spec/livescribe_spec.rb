require_relative "../lib/livescribe.rb"

describe Livescribe do
  describe "#initialize" do
    it "uses input verbatim when it contains no entities" do
      expect(Livescribe.to_markdown("test")).to eq("<p>test</p>\n")
    end
    
    it "decodes hexidecimal entities" do
      expect(Livescribe.to_markdown("test&#39;s")).to eq("<p>test's</p>\n")
    end

    it "decodes decimal entities" do
      expect(Livescribe.to_markdown("test&#x0027;s")).to eq("<p>test's</p>\n")
    end

    it "decodes named entities" do
      expect(Livescribe.to_markdown("test&apos;s")).to eq("<p>test's</p>\n")
    end
  end

  describe "#remove_line_breaks!" do
    it "removes <br> elements"
    it "does nothing when there are no line breaks"
  end

  describe "#guess_new_paragraphs!" do
    context "when the line ends with punctuation" do
      it "adds a break & keeps next alphabetic characters"
      it "adds a break & keeps next non-alphabetic characters"
    end

    context "when the line DOES NOT end with punctuation" do
      it "does nothing"
    end
  end

  describe "#remove_whitespace_around_asterisks!" do
    context "with surrounding spaces" do
      it "removes them from the first asterisk"
      it "removes them from the second asterisk"
      it "removes them from both asterisks"
    end

    context "with spaces before" do
      it "removes them from the first asterisk"
      it "removes them from the second asterisk"
      it "removes them from both asterisks"
    end

    context "with spaces after" do
      it "removes them from the first asterisk"
      it "removes them from the second asterisk"
      it "removes them from both asterisks"
    end

    context "with no spaces" do
      it "does nothing to the first asterisk"
      it "does nothing to the second asterisk"
      it "does nothing to either asterisk"
    end
  end

  describe "#fix_quotation_marks!" do
    it "replaces double apostrophes with a quotation mark"
    it "does nothing to single apostrophes"
    it "does nothing to two apostrophes in the same line"
  end

  describe "#fix_em_dashes!" do
    context "at the start of a line" do
      it "fixes when spaces surround the hyphen"
      it "fixes when spaces are before the hyphen"
      it "fixes when spaces are after the hyphen"
      it "fixes when no spaces surround the hyphen"
    end

    context "NOT at the start of a line" do
      context "with surrounding spaces" do
        it "removes them from the first hyphen"
        it "removes them from the second hyphen"
        it "removes them from both hyphens"
      end

      context "with spaces before" do
        it "removes them from the first hyphen"
        it "removes them from the second hyphen"
        it "removes them from both hyphens"
      end

      context "with spaces after" do
        it "removes them from the first hyphen"
        it "removes them from the second hyphen"
        it "removes them from both hyphens"
      end

      context "with no spaces" do
        it "does nothing to the first hyphen"
        it "does nothing to the second hyphen"
        it "does nothing to either hyphen"
      end
    end

    context "ignores list items" do
      it "when spaces surround the hyphen"
      it "when spaces are before the hyphen"
      it "when spaces are after the hyphen"
      it "when no spaces surround the hyphen"
    end

    context "when the hyphen isn't clearly an em-dash OR a list item" do
      it "ignores single hyphens within a line"
    end
  end

  describe "#wrap_smileys_in_tt!" do
    context "when there are leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)"
        it "wraps smileys like :("
        it "wraps smileys like :P"
        it "wraps smileys like ;)"
        it "wraps smileys like ;("
        it "wraps smileys like ;P"
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")"
        it "wraps smileys like \"("
        it "wraps smileys like \"P"
      end
    end

    context "when there are NOT leading spaces" do
      context "and it gets the eyes right" do
        it "wraps smileys like :)"
        it "wraps smileys like :("
        it "wraps smileys like :P"
        it "wraps smileys like ;)"
        it "wraps smileys like ;("
        it "wraps smileys like ;P"
      end

      context "and it thinks the eyes are quotation marks" do
        it "wraps smileys like \")"
        it "wraps smileys like \"("
        it "wraps smileys like \"P"
      end
    end
  end

  describe "#question_superscript!" do
    context "when there are leading spaces" do
      it "identifies leading parenthesis as C"
      it "identifies leading parenthesis as ("
      it "ignores other characters inside parentheses"
    end

    context "when there are NOT leading spaces" do
      it "identifies leading parenthesis as C"
      it "identifies leading parenthesis as ("
      it "ignores other characters inside parentheses"
    end
  end

  describe ".to_markdown" do
    it "converts properly"
  end
end
