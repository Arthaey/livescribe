# From http://stackoverflow.com/a/9654275/1867798
class String
  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.size ||  0
    gsub(/^[ \t]{#{indent}}/, '')
  end
end
