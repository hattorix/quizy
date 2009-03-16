class BooksController < ApplicationController
  
  before_filter :login_required, :only =>["new","edit","destroy"]
  layout :select_layout

  def select_layout
    if action_name == "training_start"
      "training"
    elsif %w(answer next back).include?(action_name)
    else
      "application"
    end
  end
  
  
  # GET /books
  # GET /books.xml
  def index
    @books = Book.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @books }
    end
  end

  # GET /books/1
  # GET /books/1.xml
  def show
    @book = Book.find(params[:id])
    if user = User.find(:first, :conditions =>["id =?",@book.user_id])
      @user_name = user.login
    else
      @user_name = "-"
    end
    if @book.is_smart == true
      if @book.tags != ""
        questions_t = Array.new
        @tags = @book.tags.split(",")
        @tags.each do |tag|
          questions_t << Question.find_tagged_with(tag)
        end
        questions_t.flatten!.uniq!
      end

      if @book.categories != ""
        questions_c = Array.new
        @categories = @book.categories.split(",")
        @categories.each do |category_name|
          category = Category.find(:first, :conditions => ['name = ?', category_name])
          questions_c << Question.find(:all, :conditions => ['category_id = ? and is_public = 1', category.id])
        end
        questions_c.flatten!.uniq!
      end

      if questions_t && questions_c
        @questions = (questions_t & questions_c)
      elsif @questions = questions_c
        @tags = Array.new
      elsif @questions = questions_t
        @categories = Array.new
      else
        @questions = Array.new
        @tags = Array.new
        @categories = Array.new
      end

    end
  end

  # GET /books/new
  # GET /books/new.xml
  def new
    @book = Book.new
    @tags = Question.tag_counts
    @categories = Category.find(:all, :order => 'id')

  end

  def edit
    @book = Book.find(params[:id])
    if @book.user_id != current_user.id
      redirect_to :action => "show", :id => params[:id]
    end
    @tags = Question.tag_counts
    if @book.is_smart == true
      @books_tags = @book.tags.split(",")
      @books_categories = @book.categories.split(",")
      @categories = Category.find(:all, :order => 'id')
    end

  end

  def create
    @book = Book.new(params[:book])
    @book.user_id = current_user.id

    if @book.name != "自分で登録した問題"
      if @book.save
        tags = @book.tags.split(",")
        tags.delete("")
        @book.update_attribute(:tags ,tags.join(","))
        categories = @book.categories.split(",")
        categories.delete("")
        @book.update_attribute(:categories ,categories.join(","))
        my_book = MyBook.new
        my_book.book_id = @book.id
        my_book.user_id = current_user.id
        my_book.save
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

  # PUT /books/1
  # PUT /books/1.xml
  def update
    @book = Book.find(params[:id])
    if @book.name != "自分で登録した問題"
      if @book.update_attributes(params[:book]) && @book.name != "自分で登録した問題"
        if @book.is_smart == true
          tags = @book.tags.split(",")
          tags.delete("")
          @book.update_attribute(:tags ,tags.join(","))
          categories = @book.categories.split(",")
          categories.delete("")
          @book.update_attribute(:categories ,categories.join(","))
        else
          if params[:is_collect]
            params[:is_collect].each_pair do |id,value|
              q = Question.find(id.to_i)
              @book.questions.delete(q)
            end
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

  def training_start
    # 数値が未入力の場合
    if params[:select_count] == ""
      redirect_to :action => 'show',:id => params[:id]
    else
      @id = params[:id]
      @book = Book.find(params[:id])
      @books_questions = QuestionBook.find(:all, :conditions => ["book_id = ?",params[:id]])
      # スマートブックではない場合
      if @book.is_smart != true
        # ブックに問題が登録されていない場合
        if @books_questions.size == 0
          redirect_to :action => 'show',:id => params[:id]
        else
          @questions = Array.new
          # 全ての問題からの場合
          if params[:training_type] == "all"
            params[:select_count].to_i.times do |i|
              @questions << Question.find(@books_questions[rand(@books_questions.size)].question_id)
            end
          # 苦手問題の場合
          elsif params[:training_type] == "weak"
            weak_questions = Array.new
            @books_questions.each do |books_question|
              my_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ?",books_question.question_id,current_user.id])
              if my_questions.size != 0
                my_true_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ? and correct_or_wrong = 1",books_question.question_id,current_user.id])
                weak_line = Setting.find(:first,:conditions => ["user_id = ?",current_user.id]).weak_line
                if ((my_true_questions.size*100)/my_questions.size) < weak_line
                  weak_questions << books_question
                end
              else
                weak_questions << books_question
              end
            end
            if weak_questions.size != 0
              params[:select_count].to_i.times do |i|
                @questions << Question.find(weak_questions[rand(weak_questions.size)].question_id)
              end
            end
          # 解答数の場合
          elsif params[:training_type] == "quiz_count"
            if params[:quiz_count] != ""
              low_questions = Array.new
              @books_questions.each do |books_question|
                if my_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ?",books_question.question_id,current_user.id])
                  if my_questions.size < params[:quiz_count].to_i
                    low_questions << books_question
                  end
                else
                  low_questions << books_question
                end
              end
              if low_questions.size != 0
                params[:select_count].to_i.times do |i|
                  @questions << Question.find(low_questions[rand(low_questions.size)].question_id)
                end
              end
            end
          end

          if @questions.size == 0
            redirect_to :action => 'show',:id => params[:id]
          else
            question_ids = Array.new
            @questions.each do |question|
              question_ids << question.id
            end
            traning_show(:questions => question_ids,:i => 0)
            render :action => 'training'
          end
        end
      # スマートブックの場合
      else
        @questions = Array.new

        if @book.tags != ""
          @tags = @book.tags.split(",")
          questions_t = Array.new
          @tags.sort_by{rand}.each do |tag|
            questions_t << Question.find_tagged_with(tag)
          end
          questions_t.flatten!.uniq!
        end

        if @book.categories != ""
          @categories = @book.categories.split(",")
          questions_c = Array.new
          @categories.sort_by{rand}.each do |category_name|
            category = Category.find(:first, :conditions => ['name = ?', category_name])
            questions_c << Question.find(:all, :conditions => ['category_id = ? and is_public = 1', category.id])
          end
          questions_c.flatten!.uniq!
        end

        if questions_t && questions_c
          @smart_questions = (questions_t & questions_c)
        elsif @smart_questions = questions_c
        elsif @smart_questions = questions_t
        end

        # 全ての問題からの場合
        if params[:training_type] == "all"
          params[:select_count].to_i.times do |i|
            @questions << Question.find(@smart_questions[rand(@smart_questions.size)].id)
          end
        # 苦手問題の場合
        elsif params[:training_type] == "weak"
          weak_questions = Array.new
          @smart_questions.each do |smart_question|
            my_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ?",smart_question.id,current_user.id])
            if my_questions.size != 0
              my_true_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ? and correct_or_wrong = 1",smart_question.id,current_user.id])
              weak_line = Setting.find(:first,:conditions => ["user_id = ?",current_user.id]).weak_line
              if ((my_true_questions.size*100)/my_questions.size) < weak_line
                weak_questions << smart_question
              end
            else
              weak_questions << smart_question
            end
          end
          if weak_questions.size != 0
            params[:select_count].to_i.times do |i|
              @questions << Question.find(weak_questions[rand(weak_questions.size)].id)
            end
          end
        # 解答数の場合
        elsif params[:training_type] == "quiz_count"
          if params[:quiz_count] != ""
            low_questions = Array.new
            @smart_questions.each do |smart_question|
              if my_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ?",smart_question.id,current_user.id])
                if my_questions.size < params[:quiz_count].to_i
                  low_questions << smart_question
                end
              else
                low_questions << smart_question
              end
            end
            if low_questions.size != 0
              params[:select_count].to_i.times do |i|
                @questions << Question.find(low_questions[rand(low_questions.size)].id)
              end
            end
          end
        end

        if @questions.size == 0
          redirect_to :action => 'show',:id => params[:id]
        else
          question_ids = Array.new
          @questions.each do |question|
            question_ids << question.id
          end
          traning_show(:questions => question_ids,:i => 0)
          render :action => 'training'
        end
      end
    end
  end

  def next
    @id = params[:id]
    traning_show(:questions => params[:questions],:i => params[:i].to_i+1)
    render :action => 'training'
  end

  def back
    @id = params[:id]
    traning_show(:questions => params[:questions],:i => params[:i].to_i-1)
    render :action => 'training'
  end
  
  def answer
    @id = params[:id]
    @questions = params[:questions]
    @i = params[:i].to_i
    question_id = params[:question_id]
    @question = Question.find(question_id)
    # for stastics
    @question.update_attribute("question_count", @question.question_count.to_i + 1)
    @question.save

    question_type = params[:question_type]
    answer = params[:answer]

    @random = Question.find_by_sql('select id from questions order by rand() limit 1;').first.id

    # TODO: いろいろとリファクタリングすること
    if question_type == "1"
      result = Selection.count(:conditions => ["id = ? and question_id = ? and is_collect = '1'",
                                              answer, question_id])
      @result_text = ""
      @is_collect = ""
      if result > 0
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "○ 正解です！"
        @is_collect = "1"
        @question.update_attribute("correct_count", @question.correct_count.to_i + 1)
        @question.save
      else
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "× 残念です！"
        @is_collect = "0"
        @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
        @question.save
      end
    elsif question_type == "2"
      if params[:answer]
        user_answers = params[:answer].values
      else
        user_answers = Array.new
      end
      selections = Selection.find(:all, :conditions => ["question_id = ?", question_id])
      answers = selections.map {|s| s.id.to_s if s.is_collect == 1}.compact
      if (answers | user_answers).size == answers.size
        if (answers & user_answers).size == answers.size
          @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
          @result_text = "○ 正解です！"
          @is_collect = "1"
          @question.update_attribute("correct_count", @question.correct_count.to_i + 1)
          @question.save
        else
          @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
          @result_text = "× 残念です！"
          @is_collect = "0"
          @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
          @question.save
        end
      else
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "× 残念です！"
        @is_collect = "0"
        @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
        @question.save
      end
    elsif question_type == "3"
      result = Question.count(:conditions => ["id = ? and y_or_n = ?",
                                              question_id,answer])
      @result_text = ""
      @is_collect = ""
      if result > 0
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "○ 正解です！"
        @is_collect = "1"
        @question.update_attribute("correct_count", @question.correct_count.to_i + 1)
        @question.save
      else
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "× 残念です！"
        @is_collect = "0"
        @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
        @question.save
      end
    elsif question_type == "4"
      answer = params[:answer]
      p answer
      result = Answer.count(:conditions => ["question_id = ? and answer_text = ?",
                                            question_id, answer])
      if result > 0
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "○ 正解です！"
        @is_collect = "1"
        @question.update_attribute("correct_count", @question.correct_count.to_i + 1)
        @question.save
      else
        @description = Description.find(:first, :conditions => ["question_id = ?", question_id])
        @result_text = "× 残念です！"
        @is_collect = "0"
        @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
        @question.save
     end
    else
      raise("must not happend")
    end
    if logged_in?
      hist = History.new
      hist.question_id = @question.id
      hist.user_id = current_user.id
      hist.correct_or_wrong = @is_collect.to_i
      hist.answer_mode = 1
      hist.save
    end
  end

  # DELETE /books/1
  # DELETE /books/1.xml
  def destroy
    book = Book.find(params[:id])
    mybook = MyBook.find(:first, :conditions =>["book_id = ? and user_id = ?",params[:id],current_user.id])
    mybook.destroy
    if book.user_id == current_user.id
      book.questions.delete_all()
      book.destroy
    end
    redirect_to :controller => 'mypage'
  end

  def rip
      book = Book.find(params[:id])
      question = Question.find(params[:question_id])

      book.questions.delete(question)
      question.reload

      redirect_to :action => :show
  end

  def add_mybook
    @book = Book.find(params[:id])
    mybooks = MyBook.find(:all, :conditions => ["user_id = ?",current_user.id])
    book_ids = Array.new
    mybooks.each do |mybook|
      book_ids << mybook.book_id
    end
    unless book_ids.include?(params[:id].to_i)
      my_book = MyBook.new
      my_book.book_id = @book.id
      my_book.user_id = current_user.id
      my_book.save
      flash[:notice] = "マイブックに登録しました！"
      render :update do |page|
        page.replace_html("add_mybook_message", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_mybook_message",
                           :from => 1,
                           :to => 0,
                           :duration => 3
      end
    else
      flash[:notice] = "登録済みです"
      render :update do |page|
        page.replace_html("add_mybook_message", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                           "add_mybook_message",
                           :from => 1,
                           :to => 0,
                           :duration => 3
      end
    end
  end
  
  private
  
  def traning_show(params)
    @questions = params[:questions]
    @i = params[:i]
    @question = Question.find(@questions[@i])
    @selections = Selection.find(:all, :conditions => "question_id = #{@question.id} and selection_text != ''")
    @answer = Answer.find(:all, :conditions => "question_id = #{@question.id}")
    @description = Description.find(:all, :conditions => "question_id = #{@question.id}")

    # statstics information
    my_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ?",@question.id,current_user.id])
    if my_questions.size != 0
      my_true_questions = History.find(:all, :conditions =>["question_id = ? and user_id = ? and correct_or_wrong = 1",@question.id,current_user.id])
      @my_reat = ((my_true_questions.size*100)/my_questions.size)
    else
      @my_reat = 0
    end

    right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
    @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
    @question_count = @question.question_count
    @correct_count = @question.correct_count
    @wrong_count = @question.wrong_count
  end
end
