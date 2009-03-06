class SearchController < ApplicationController
  def category
    @results = Question.find(:all, :conditions => ['category_id = ? and is_public = 1', params[:id]])
#    render :partial => 'results', :collection => results
    @flg = 0
    render :action => :index
  end

  def tag
    @results = Question.find_tagged_with(params[:id])
    @flg = 0
    render :action => :index
  end

  def text
    keywords = params[:id].split(/\s|　/)
    if keywords.size > 0
      @results_hash = Hash.new
      @results = Array.new
      @flg = params[:search_for].to_i
      i = 0
      keywords.each do |keyword|
        if @flg == 0
          @results_hash[i] = Question.find(:all, :conditions => ['question_text like ? and is_public = 1', "%#{keyword}%"])
        elsif @flg == 1
          @results_hash[i] = Tag.find(:all, :conditions => ['name like ?', "%#{keyword}%"])
        elsif @flg == 2
          @results_hash[i] = Book.find(:all, :conditions => ['(name like ? or outline like ?) and is_public = 1 ', "%#{keyword}%","%#{keyword}%"])
        elsif @flg == 3
          @results_hash[i] = Exam.find(:all, :conditions => ['name like ? and is_public = 1', "%#{keyword}%"])
        end
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
      redirect_to :controller => :top
    end
  end
  
  def add_book
    if params[:id] == "all"
      if params[:add_book_to]
        book = Book.find(params[:add_book_to])
        question_ids = params[:results]
        i = 0
        question_ids.each do |question_id|
          question = Question.find(question_id.to_i)
          unless book.questions.include?(question)
            book.questions << question
            i += 1
          end
        end
        if i == 0
          flash[:notice] = "全て登録済みです。"
          flug = false
        else
          flash[:notice] = "#{i}件登録しました！"
          flug = true
        end
      else
        flash[:notice] = "ブックが存在しません。"
        flug = false
      end
      render :update do |page|
        page.replace_html("add_book_message_all", :partial=>"message",:locals => {:flug => flug})
        page.visual_effect :Opacity,
                            "add_book_message_all",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    else
      if params[:add_book_to]
        book = Book.find(params[:add_book_to])
        question = Question.find(params[:id])
        if book.questions.include?(question)
          flash[:notice] = "登録済みです。"
          flug = false
        else
          book.questions << question
          flash[:notice] = "登録しました！"
          flug = true
        end
      else
        flash[:notice] = "ブックが存在しません。"
        flug = false
      end
      render :update do |page|
        page.replace_html("add_book_message#{params[:id]}", :partial=>"message",:locals => {:flug => flug})
        page.visual_effect :Opacity,
                            "add_book_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    end
  end

  def search_book
    @results = Array.new
    book_questions = QuestionBook.find(:all, :conditions => ["question_id = ?",params[:id]])
    book_questions.each do |book_question|
      if book = Book.find(:first, :conditions => ["id = ? and is_public = 1",book_question.book_id])
        @results << book
      end
    end
    @flg = 2
    render :action => :index

  end

  def search_exam
    @results = Array.new
    exam_questions = QuestionExam.find(:all, :conditions => ["question_id = ?",params[:id]])
    exam_questions.each do |exam_question|
      if exam = Exam.find(:first, :conditions => ["id = ? and is_public = 1",exam_question.exam_id])
        @results << exam
      end
    end
    @flg = 3
    render :action => :index

  end
end
