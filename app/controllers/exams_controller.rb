class ExamsController < ApplicationController
  # GET /exams
  # GET /exams.xml
  before_filter :login_required, :only =>["new","edit","destroy"]

  layout :select_layout

  def select_layout
    if action_name == "start"
      "examination"
    elsif %w(next back check finish).include?(action_name)
    else
      "application"
    end
#    %w(start back check finish).include?(action_name) ? "examination" : "application"
  end

  def index
    @exams = Exam.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @exams }
    end
  end

  # GET /exams/1
  # GET /exams/1.xml
  def show
    @exam = Exam.find(params[:id])
    @user_name = User.find(@exam.user_id).login
  end

  # GET /exams/new
  # GET /exams/new.xml
  def new
    @exam = Exam.new
    @book = Book.find(params[:id])
    # スマートブックの場合
    if @book.is_smart == true
      # タグが設定されている場合
      if @book.tags != ""
        questions_t = Array.new
        @tags = @book.tags.split(",")
        @tags.each do |tag|
          questions_t << Question.find_tagged_with(tag)
        end
        questions_t.flatten!.uniq!
      end
      # カテゴリが設定されている場合
      if @book.categories != ""
        questions_c = Array.new
        @categories = @book.categories.split(",")
        @categories.each do |category_name|
          category = Category.find(:first, :conditions => ['name = ?', category_name])
          questions_c << Question.find(:all, :conditions => ['category_id = ? and is_public = 1', category.id])
        end
        questions_c.flatten!.uniq!
      end
      # タグとカテゴリ両方が設定されている場合
      if questions_t && questions_c
        @questions = (questions_t & questions_c)
      elsif @questions = questions_c
        @tags = Array.new
      elsif @questions = questions_t
        @categories = Array.new
      end
    else
      @questions = @book.questions
    end
  end

  def edit
    @exam = Exam.find(params[:id])
    if @exam.time_limit == 0
      @exam.time_limit = ""
    end

    if @exam.user_id != current_user.id
      redirect_to :action => "show", :id => params[:id]
    end
    @question_exams = QuestionExam.find(:all, :conditions => "exam_id = #{params[:id]}")
  end

  def create
    @exam = Exam.new(params[:exam])
    @exam.user_id = current_user.id
    @exam.book_id = params[:id]
    @exam.questions.delete_all

    unless params[:time_limit_config]
      @exam.time_limit = 0
    end

    book = Book.find(params[:id])
    book.questions.each do |question|
      @exam.questions << question
    end

    if @exam.save
      my_exam = MyExam.new
      my_exam.exam_id = @exam.id
      my_exam.user_id = current_user.id
      my_exam.save

      @question_exams = QuestionExam.find(:all, :conditions => "exam_id = #{@exam.id}")
      i = 0
      @question_exams.each do |question_exam|
        question_exam.update_attribute("seq", i)
        question_exam.update_attribute("enabled", 1)
        question_exam.save
        i += 1
      end
      render :update do |page|
          page.redirect_to :controller => "mypage",:action => "message",:message => "テストを作成しました。"
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

  def start
    @exam = Exam.find(params[:id])
    @question_exams = QuestionExam.find(:all, :conditions => ["exam_id = ? and enabled = 1",@exam.id], :order => "seq")
    @i = 0
    @question_exam = @question_exams[@i]
    question_id = @question_exam.question_id
    @question = Question.find(question_id)
    @selections = Selection.find(:all, :conditions => ["question_id = ? and selection_text != ''",@question.id])
    @answer = Answer.find(:all, :conditions => ["question_id = ?",@question.id])
    @description = Description.find(:all, :conditions => ["question_id = ?",@question.id])

    @seq = 0

    if @temp = ExamTemp.delete_all(["exam_id = ? and user_id = ?",
                                params[:id],current_user.id])
    end

    # statstics information
    right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
    @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
    @question_count = @question.question_count
    @correct_count = @question.correct_count
    @wrong_count = @question.wrong_count
  end
  
  def next

    quiz()

    @exam = Exam.find(params[:id])
    @question_exams = QuestionExam.find(:all, :conditions => ["exam_id = ? and enabled = 1",@exam.id], :order => "seq")
    @i = params[:i].to_i+1
    @question_exam = @question_exams[@i]
    question_id = @question_exam.question_id

    @question = Question.find(question_id)
    @selections = Selection.find(:all, :conditions => "question_id = #{@question.id} and selection_text != ''")
    @answer = Answer.find(:all, :conditions => "question_id = #{@question.id}")
    @description = Description.find(:all, :conditions => "question_id = #{@question.id}")
    @books = Book.find(:all, :conditions => ["user_id = ? or is_public = 1", current_user.id])
    
    # statstics information
    right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
    @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
    @question_count = @question.question_count
    @correct_count = @question.correct_count
    @wrong_count = @question.wrong_count
    render :action => 'start'
  end
  
  def back
    @exam = Exam.find(params[:id])
    @question_exams = QuestionExam.find(:all, :conditions => ["exam_id = ? and enabled = 1",@exam.id], :order => "seq")
    @i = params[:i].to_i-1
    @question_exam = @question_exams[@i]
    question_id = @question_exam.question_id

    @question = Question.find(question_id)
    @selections = Selection.find(:all, :conditions => "question_id = #{@question.id} and selection_text != ''")
    @answer = Answer.find(:all, :conditions => "question_id = #{@question.id}")
    @description = Description.find(:all, :conditions => "question_id = #{@question.id}")
    @books = Book.find(:all, :conditions => ["user_id = ? or is_public = 1", current_user.id])
    
    # statstics information
    right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
    @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
    @question_count = @question.question_count
    @correct_count = @question.correct_count
    @wrong_count = @question.wrong_count
    render :action => 'start'
  end
  
  def check

    quiz()

    @exam = Exam.find(params[:id])
    question_exam = QuestionExam.find(:first, :conditions => ["exam_id = ? and question_id = ?",
                                                              params[:id],params[:question_id]])
    @seq = question_exam.seq.+1
    if QuestionExam.find(:all, :conditions => {:exam_id => @exam.id, :seq => @seq}).size == 0
    else
      @question_exam = QuestionExam.find(:first, :conditions => ["exam_id = ? and seq = ?",
                                                               params[:id],@seq])
      question_id = @question_exam.question_id

      @question = Question.find(question_id)
      @selections = Selection.find(:all, :conditions => "question_id = #{@question.id} and selection_text != ''")
      @answer = Answer.find(:all, :conditions => "question_id = #{@question.id}")
      @description = Description.find(:all, :conditions => "question_id = #{@question.id}")
      @books = Book.find(:all, :conditions => ["user_id = ? or is_public = 1", current_user.id])
    
      # statstics information
      right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
      @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
      @question_count = @question.question_count
      @correct_count = @question.correct_count
      @wrong_count = @question.wrong_count
    end
  end

  def finish
    if params[:question_id]
      quiz()
    end

    @count = ExamTemp.count(:conditions => ["exam_id = ? and user_id = ? and t_or_f = ?",
                                                     params[:id], current_user.id, 1])
    @exam = Exam.find(params[:id])
    @question_exams = QuestionExam.find(:all, :conditions => ["exam_id = ? and enabled = 1",@exam.id], :order => "seq")

    @border = @exam.border_line
    @point = @count * 100 / @question_exams.size
    
    @examtemps = ExamTemp.find(:all,:conditions => ["exam_id = ? and user_id = ?",
                                                      params[:id],current_user.id])

    if logged_in?
      @examtemps.each do |examtemp|
        hist = History.new
        hist.question_id = examtemp.question_id
        hist.user_id = current_user.id
        hist.correct_or_wrong = examtemp.t_or_f
        hist.answer_mode = 2
        hist.save
      end
    end

    ExamTemp.delete_all(["exam_id = ? and user_id = ?",
                                params[:id],current_user.id])

    if @point >= @border
      @result_text = "合格です！おめでとうございます！"
      @t_or_f = 1
    else
      @result_text = "不合格です。"
      @t_or_f = 0
    end

  end

  def sort_questions
    params[:sortable_question_list].each_with_index do |id, i|
      question_exams = QuestionExam.find(:all,:conditions => ["question_id = ? and exam_id = ?",
                                                                id,params[:id]])
      question_exams.each do |question_exam|
        question_exam.update_attribute('seq', i)
      end
    end
  end

  # PUT /exams/1
  # PUT /exams/1.xml
  def update
    @exam = Exam.find(params[:id])
    @seq = params.inspect

    @exam.questions.each do |question|
      if params["is_collect"]
        if params["is_collect"][question.id.to_s] == "on"
          question_exam = QuestionExam.find(:first,:conditions => ["question_id = ? and exam_id = ?",
                                                                      question.id,params[:id]])
            question_exam.update_attribute("enabled",1)
        else
          question_exam = QuestionExam.find(:first,:conditions => ["question_id = ? and exam_id = ?",
                                                                  question.id,params[:id]])
          question_exam.update_attribute("enabled",0)
        end
      else
        question_exam = QuestionExam.find(:first,:conditions => ["question_id = ? and exam_id = ?",
                                                                  question.id,params[:id]])
        question_exam.update_attribute("enabled",0)
      end
    end

    unless params[:time_limit_config]
      @exam.time_limit = 0
    end

    if @exam.update_attributes(params[:exam])
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

  # DELETE /exams/1
  # DELETE /exams/1.xml
  def destroy
    exam = Exam.find(params[:id])
    myexam = MyExam.find(:first, :conditions =>["exam_id = ? and user_id = ?",params[:id],current_user.id])
    myexam.destroy
    message = "マイテストからテストを削除しました。"
    if exam.user_id == current_user.id
      exam.questions.delete_all()
      exam.destroy
      message = "テストを削除しました。"
    end
      redirect_to :controller => "mypage",:action => "message",:message => message
  end

  def rip
      exam = Exam.find(params[:id])
      question = Question.find(params[:question_id])

      exam.questions.delete(question)
      question.reload

      redirect_to :action => :show
  end

  def add_myexam
    @exam = Exam.find(params[:id])
    myexams = MyExam.find(:all, :conditions => ["user_id = ?",current_user.id])
    exam_ids = Array.new
    myexams.each do |myexam|
      exam_ids << myexam.exam_id
    end
    unless exam_ids.include?(params[:id].to_i)
      my_exam = MyExam.new
      my_exam.exam_id = @exam.id
      my_exam.user_id = current_user.id
      my_exam.save
      flash[:notice] = "マイテストに登録しました！"
      render :update do |page|
        page.replace_html("add_myexam_message", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_myexam_message",
                           :from => 1,
                           :to => 0,
                           :duration => 3
      end
    else
      flash[:notice] = "登録済みです"
      render :update do |page|
        page.replace_html("add_myexam_message", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                           "add_myexam_message",
                           :from => 1,
                           :to => 0,
                           :duration => 3
      end
    end
  end



private

  def quiz()
      if @temp = ExamTemp.find(:first, :conditions => ["exam_id = ? and question_id = ? and user_id = ?",
                                                       params[:id], params[:question_id], current_user.id])
      else
        @temp = ExamTemp.new()
      end
      @temp.exam_id = params[:id]
      @temp.question_id = params[:question_id]
      @temp.user_id = current_user.id
      if params[:review] == "on"
        @temp.status = "review"
      else
        @temp.status = ""
      end

      @question = Question.find(params[:question_id])
      if @question.question_type == 2
        answers = Array.new
        if !params[:answer].nil?
          answers = params[:answer].values
        end
        @temp.answer = answers.join(",")
      else
        @temp.answer = params[:answer]
      end

      if @question.question_type == 1
        result = Selection.count(:conditions => ["id = ? and question_id = ? and is_collect = '1'",
                                              @temp.answer, @temp.question_id])
        if result > 0
          @temp.t_or_f = 1
          @temp.save
        else
          @temp.t_or_f = 0
          @temp.save
        end
      elsif @question.question_type == 2
        user_answers = @temp.answer.split(",")
        selections = Selection.find(:all, :conditions => ["question_id = ?", @temp.question_id])
        answers = selections.map {|s| s.id.to_s if s.is_collect == 1}.compact
        if (answers | user_answers).size == answers.size
            if (answers & user_answers).size == answers.size
              @temp.t_or_f = 1
              @temp.save
            else
              @temp.t_or_f = 0
              @temp.save
            end
        else
          @temp.t_or_f = 0
          @temp.save
        end
      elsif @question.question_type == 3
        result = Question.count(:conditions => ["id = ? and y_or_n = ?",
                                              @question.id, @temp.answer])
        if result > 0
          @temp.t_or_f = 1
          @temp.save
        else
          @temp.t_or_f = 0
          @temp.save
        end
      elsif @question.question_type == 4
        result = Answer.count(:conditions => ["question_id = ? and answer_text = ?",
                                              @temp.question_id, @temp.answer])
        if result > 0
          @temp.t_or_f = 1
          @temp.save
        else
          @temp.t_or_f = 0
          @temp.save
       end
      else
        raise("must not happend")
      end
  end
end
