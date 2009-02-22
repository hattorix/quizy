require 'erb'

def take_block(lines, marker)
  buf = []
  until lines.empty?
    break unless marker =~ lines.first
    buf.push lines.shift.sub(marker, '')
  end
  buf
end


def qa_to_html(str = "")
  lines = str.to_a
  p take_block(lines, />C>|<C</)

#  lines.each do |line|
#    case line
#      when />C>/
#        line.replace('<pre class="code">')
#      when /<C</
#        line.replace('</pre>')
#      when />P>/
#        line.replace('<pre class="prompt">')
#      when /<P</
#        line.replace('</pre>')
#      else
#        line
#    end
#  end
#
#  lines.each do |line|
#    if line =~ 
#    line.replace(ERB::Util.html_escape(line))
#
#  end

  lines
#  str.gsub("\n", "<br />")
end

qa_to_html(DATA.read).each do |h|
  puts h
end

__END__
>C>
<b>piyo</b>
piko
<C<