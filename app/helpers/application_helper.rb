# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper

  def erase_tag(str = "")
    str.gsub(/<.+?>/, "")
  end

  def qa_to_html(str = "")
    str.gsub("\n", "<br />")
  end

  def html_to_qa(str = "")
    str.gsub("<br />", "\n")
  end
  
  def hbr(str)
    str = html_escape(str)
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  #QA記法
  def qa(str)
    @qas ||= /
       >C>(.*?)<C<                 # $1: コード
     | >P>(.*?)<P<                 # $2: プロンプト
     | >B>(.*?)<B<                 # $3: 引用
     | ''(.*?)''                   # $4: 太字
     | __(.*?)__                   # $5: 下線
     | \[(.*?)\[.*?\]\]            # $6: 虫食い
     /xm
    
    str.gsub(@qas) {
      case
        when code = $1
          code.gsub!(/^[\r\n|\r|\n]/, "")
          "<div class='code'>#{code}</div>"
        when prompt = $2
          prompt.gsub!(/^[\r\n|\r|\n]/, "")
          "<div class='prompt'>#{prompt}</div>"
        when blockquote = $3
          blockquote.gsub!(/^[\r\n|\r|\n]/, "")
          "<blockquote>#{blockquote}</blockquote>"
        when strong = $4
          "<span class='strong'>#{strong}</span>"
        when underline = $5
          "<span class='underline'>#{underline}</span>"
        when worm = $6
          if worm == ""
            worm = "　　　"
          end
          "<span class='worm'>#{worm}</span>"
      end
    }
  end
end
