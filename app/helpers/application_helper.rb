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
end
