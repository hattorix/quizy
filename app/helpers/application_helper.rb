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

  def erase_br(str = "")
    str.gsub("<br />", " ").gsub("\n", " ")
  end

  def hbr(str)
    str = html_escape(str)
    str.gsub(/\r\n|\r|\n/, "<br />")
  end

  #QA記法
  def qa(str)
    @qas ||= /
       &gt;C:?(.*?)&gt;(.*?)&lt;C&lt;     # $1,2: 言語,コード
     | &gt;P&gt;(.*?)&lt;P&lt;            # $3: プロンプト
     | &gt;B&gt;(.*?)&lt;B&lt;            # $4: 引用
     | ''(.*?)''                          # $5: 太字
     | __(.*?)__                          # $6: 下線
     | \[(.*?)\[.*?\]\]                   # $7: 虫食い
     /xm

    new_str = html_escape(str)

    while new_str.match(@qas) do
      new_str.gsub!(@qas) {
        case
          when code = $2
            language = $1
            if language == ""
              language = "text"
            end
            code.gsub!(/^\r\n+?|^\r+?|^\n+?/, "")
            code.gsub!(/\r\n|\n/, "\r")
            "<pre class=\"brush:#{language} toolbar:false\">#{code}</pre>"
          when prompt = $3
            prompt.gsub!(/^\r\n+?|^\r+?|^\n+?/, "")
            "<div class='prompt'>#{prompt}</div>"
          when blockquote = $4
            blockquote.gsub!(/^\r\n+?|^\r+?|^\n+?/, "")
            "<blockquote>#{blockquote}</blockquote>"
          when strong = $5
            "<span class='strong'>#{strong}</span>"
          when underline = $6
            "<span class='underline'>#{underline}</span>"
          when worm = $7
            if worm == ""
              worm = "　　　"
            end
            "<span class='worm'>#{worm}</span>"
          else
            raise 'must not happen'
        end
      }
    end
    str = qa_to_html(new_str)
  end

  def qa_erase(str)
    @qas ||= /
       &gt;C:?(.*?)&gt;(.*?)&lt;C&lt;     # $1,2: 言語,コード
     | &gt;P&gt;(.*?)&lt;P&lt;            # $2: プロンプト
     | &gt;B&gt;(.*?)&lt;B&lt;            # $3: 引用
     | ''(.*?)''                          # $4: 太字
     | __(.*?)__                          # $5: 下線
     | \[(.*?)\[.*?\]\]                   # $6: 虫食い
     /xm

    new_str = html_escape(str)

    while new_str.match(@qas) do
      new_str.gsub!(@qas) {
        case
          when code = $2
            code
          when prompt = $3
            prompt
          when blockquote = $4
            blockquote
          when strong = $5
            strong
          when underline = $6
            underline
          when worm = $7
            if worm = ""
              worm = "　　　"
            end
            worm
          else
            raise 'must not happen'
        end
      }
    end
    str = new_str
  end

end
