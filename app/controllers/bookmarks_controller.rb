class BookmarksController < ApplicationController
  before_filter :login_required
  def index
    @questions = Array.new
    bookmarks = Bookmark.find(:all, :conditions => ["user_id = ?",current_user.id])
    bookmarks.each do |bookmark|
      question = Question.find(bookmark.question_id)
      @questions << question
    end
  end

  def bookmark_actions
    if params[:commit] == "選択した付箋を剥がす"
      params[:is_collect].each do |id|
        if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",id,current_user.id])
          bookmark.destroy
        end
      end
      redirect_to :action => :index
    elsif params[:commit] == "選択した付箋からブックを作成する"
      @book = Book.new
      @is_collect = params[:is_collect]
      render :action => "new_book"
    else
      @exam = Exam.new
      @is_collect = params[:is_collect]
      render :action => "new_exam"
    end
  end

  def create_book
    @book = Book.new(params[:book])
    @book.user_id = current_user.id

    params[:is_collect].each do |id|
      question = Question.find(id)
      @book.questions << question
    end


    if @book.name != "自分で登録した問題"
      if @book.save
        my_book = MyBook.new
        my_book.book_id = @book.id
        my_book.user_id = current_user.id
        my_book.save

        if params[:off_bookmark] == "on"
          params[:is_collect].each do |id|
            bookmark = Bookmark.find(:first, :conditions => ["user_id = ? and question_id = ?",current_user.id,id])
            bookmark.destroy
          end
        end

        render :update do |page|
          page.redirect_to :controller => "mypage"
        end
      else
        @msgs = @book.errors.full_messages
        render :update do |page|
          page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
          page[:msg].visual_effect :highlight,
                                    :startcolor => "#ffd900",
                                    :endcolor => "#ffffff",
                                    :duration => 1.5
        end
      end
    else
      @book.valid?
      @msgs = @book.errors.full_messages
      @msgs << "そのブック名は使用できません。"
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end

  def create_exam
    @exam = Exam.new(params[:exam])
    @exam.user_id = current_user.id
    @exam.book_id = params[:id]
    @exam.questions.delete_all

    unless params[:time_limit_config]
      @exam.time_limit = 0
    end

    params[:is_collect].each do |id|
      question = Question.find(id)
      @exam.questions << question
    end

    if @exam.save
      my_exam = MyExam.new
      my_exam.exam_id = @exam.id
      my_exam.user_id = current_user.id
      my_exam.save

    if params[:off_bookmark] == "on"
      params[:is_collect].each do |id|
        bookmark = Bookmark.find(:first, :conditions => ["user_id = ? and question_id = ?",current_user.id,id])
        bookmark.destroy
      end
    end

      @question_exams = QuestionExam.find(:all, :conditions => "exam_id = #{@exam.id}")
      i = 0
      @question_exams.each do |question_exam|
        question_exam.update_attribute("seq", i)
        question_exam.update_attribute("enabled", 1)
        question_exam.save
        i += 1
      end
      render :update do |page|
        page.redirect_to :controller => "mypage"
      end
    else
      @msgs = @exam.errors.full_messages
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end

end
