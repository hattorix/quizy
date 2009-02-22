class SearchController < ApplicationController
  def category
    @results = Question.find(:all, :conditions => ['category_id = ?', params[:id]])
#    render :partial => 'results', :collection => results
    render :action => :index
  end

  def tag
    @results = Question.find_tagged_with(params[:id])
    render :action => :index
  end

  def text
    keywords = params[:id].split(/\s|　/)
    if keywords.size > 0
      @results_hash = Hash.new
      @results = Array.new
      if params[:search_for].to_i == 0
        i = 0
        keywords.each do |keyword|
          @results_hash[i] = Question.find(:all, :conditions => ['question_text like ?', "%#{keyword}%"])
          i += 1
        end
        @results = @results_hash[0]
        if keywords.size >= 2
          if params[:searchtype] == "and"
            (@results_hash.size-1).times do |i|
              @results = (@results & @results_hash[i+1]) 
            end
            @results.uniq!
          else
            (@results_hash.size-1).times do |i|
              @results = @results.concat(@results_hash[i+1])
            end
            @results.uniq!
          end
        end
        render :action => :index
      else
        tags = Array.new
        keywords.each do |keyword|
          tags << Tag.find(:all, :conditions => ['name like ?',"%#{keyword}%"])
        end
        tags.each do |tag|
          @results << Question.find_tagged_with(tag)
        end
        if keywords.size >= 2
          if params[:searchtype] == "and"
            resultsouts = @results.flatten.uniq
            @results.flatten!
            resultsouts.each do |resultsout|
              i = @results.index(resultsout)
              @results.delete_at(i)
            end
          else
            @results.flatten!.uniq!
          end
        else
          @results.flatten!.uniq!
        end
        render :action => :index
      end
    else
      redirect_to :controller => :mypage
    end
  end
  
  def add_book
    book = Book.find(params[:add_book_to])
    question = Question.find(params[:id])
    if book.questions.include?(question)
      flash[:notice] = "登録済みです。"
      render :update do |page|
        page.replace_html("add_book_message#{params[:id]}", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                                  "add_book_message#{params[:id]}",
                                  :from => 1,
                                  :to => 0,
                                  :duration => 3
      end
    else
      book.questions << question
      flash[:notice] = "登録しました！"
      render :update do |page|
        page.replace_html("add_book_message#{params[:id]}", :partial=>"message",:locals => {:flug => true})
      end
    end
  end

end
