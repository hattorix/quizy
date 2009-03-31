class QaController < ApplicationController

  before_filter :login_required, :only =>["new","edit","destroy"]

  layout :select_layout

  def select_layout
    if %w(new_book).include?(action_name)
    else
      "application"
    end
  end

  def new
    # プルダウンの初期化
    @categories = Category.find(:all, :order => 'id')
    @tags = Tag.find(:all)
    @question_types = QuestionType.find(:all, :order => 'id')
  end

  def create
    # Question
    @q = Question.new
    @q.question_type = params[:question_type]

    texts = params[:question_ta].split("''")
    new_texts = Array.new
    texts.each_with_index do |text, idx|
      if idx % 2 != 0
        new_texts << "<span class=\"strong\">#{text}</span>"
      else
        new_texts << text
      end
    end

    @q.question_text = params[:question_ta]
    @q.is_public = params[:is_public]
    @q.user_id = current_user.id
    @q.category_id = params[:category]
    @q.is_random = params[:is_random]

    # Tag
    @q.tag_list = (params[:tag].to_s)

    # Answer / Selection
    a = Answer.new
    a.question_id = @q.id
    a.user_id = current_user.id

    selections = Array.new
    selection_list = Hash.new
    10.times do |i|
      selection_list[i.to_s] = ""
    end

    if params[:question_type] == "4"
      a.answer_text = params[:answer_ta]
      y_or_n = 1

    elsif params[:question_type] == "3"
      y_or_n = params[:is_collect3].to_i

    else
      if params[:question_type] == "1"
        10.times do |i|
          if s = params[:selection][i.to_s]
            selection_list[i.to_s] = s
          end
        end
        is_collect_list = params[:is_collect]
      elsif params[:question_type] == "2"
        (0..9).each do |i|
          if s = params[:selection2][i.to_s]
            selection_list[i.to_s] = s
          end
        end
        is_collect_list = params[:is_collect2]
      end
    y_or_n = 1
    end

    10.times do |i|
      s = Selection.new
      s.selection_text = selection_list[i.to_s]
      if is_collect_list
        s.is_collect = is_collect_list[i.to_s] ? 1 : 0
      else 
        s.is_collect = 0
      end
      s.question_id = @q.id
      s.user_id = current_user.id
      selections << s
    end
    @q.y_or_n = y_or_n
    @q.selections = selections
    @q.answer = a

    # Description
    d = Description.new
    d.description_text = params[:description_ta]
    d.question_id = @q.id
    d.user_id = current_user.id
    @q.description = d

    # コミット 
    if @q.save
       book = Book.find(:first,:conditions => ["name = '自分で登録した問題' and user_id =? ", current_user.id])
       book.questions << @q
      if params[:name] == 'submit1'
        flash[:notice] = "問題を登録しました。"
        render :update do |page|
          page.redirect_to :controller => "mypage"
        end
      else
        flash[:notice] = "問題を登録しました。"
        render :update do |page|
          page << 'clearFormAll()'
          page.visual_effect :ScrollTo,
                             'container',
                             :duration => 0
          page.replace_html("message", :partial=>"message",:locals => {:flug => true})
          page[:msg].visual_effect :highlight,
                                    :startcolor => "#66ffff",
                                    :endcolor => "#ffffff",
                                    :duration => 1.5
        end
      end
    else
      @msgs = @q.errors.full_messages
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page.visual_effect :ScrollTo,
                           'container',
                           :duration => 0.15
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end
  
  def quiz
    @question = Question.find(params[:question_id].to_i)
    @selections = Selection.find(:all, :conditions => "question_id = #{@question.id} and selection_text != ''")
    @answer = Answer.find(:all, :conditions => "question_id = #{@question.id}")
    @description = Description.find(:all, :conditions => "question_id = #{@question.id}")
    if logged_in?
      @books = Book.find(:all, :conditions => ["user_id = ? and name != '自分で登録した問題' and (is_smart != 1 or is_smart is null)", current_user.id])
      @is_bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?", @question.id,current_user.id])
    end

    # statstics information
    right_answer_rate = @question.correct_count.to_f / @question.question_count.to_f
    @right_answer_rate = right_answer_rate.nan? ? '---' : sprintf("%.1f%%", right_answer_rate * 100)
    @question_count = @question.question_count
    @correct_count = @question.correct_count
    @wrong_count = @question.wrong_count
  end

  def answer
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

      @answer = "『#{Selection.find(:first,:conditions => ["question_id = ? and is_collect = 1",
                                                      @question.id]).selection_text}』"

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

      selections = Selection.find(:all,:conditions => ["question_id = ? and is_collect = 1",
                                                      @question.id]) 
      answers= Array.new 
      selections.each do |selection| 
        answers << "『#{selection.selection_text}』" 
      end 
      @answer = answers.join("\n")
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

      @answer = @question.y_or_n == true ? "『○』" : "『×』" 

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

      @answer = "『#{Answer.find(:first,:conditions => ["question_id = ?",
                                                    @question.id]).answer_text}』"

    else
      raise("must not happend")
    end

    if logged_in?
      hist = History.new
      hist.question_id = @question.id
      hist.user_id = current_user.id
      hist.correct_or_wrong = @is_collect.to_i
      hist.answer_mode = 0
      hist.save
    end

    evals = Evaluation.find(:all,:conditions => ["question_id = ?",@question.id])
    @sum = 0
    @avg = 0
    @count = evals.size
    if @count > 0
      evals.each do |eval|
        @sum+=eval.point
      end
      @avg = @sum/evals.size
    end
  end

  def edit
    question_id = params[:id]
    @question = Question.find(question_id)

    if @question.user_id != current_user.id
      redirect_to :action => "quiz", :question_id => params[:id]
    end
    @tags = Tag.find(:all)
    @selections = Selection.find(:all, :conditions => "question_id = #{@question.id}", :order => "question_id")
    @answer = Answer.find(:first, :conditions => "question_id = #{@question.id}")

    @description = Description.find(:first, :conditions => "question_id = #{@question.id}")
  end
  
  def update
    # TODO: とりあえず動かしたいので適当に書いた。
    # formにquizのような連想配列をつくって、update_attributesで一気に更新したい
    
    #  TODO: QuestionType自体が変更になったときの処理
    quiz = Hash.new
    quiz[:is_public] = params[:is_public]
    quiz[:question_text] = params[:question_ta]
    quiz[:question_type] = params[:question_type]
    quiz[:category_id] = params[:category]
    quiz[:tag_list] = params[:tag]
    selections = Selection.find(:all, :conditions => ["question_id = ?", params[:question_id]])
    old_selections = []
    selections.each do |selection|
      old_selections << { "text" => selection.selection_text, "is_collect" => selection.is_collect}
    end

    new_selections = Array.new

    if params[:question_type] == "1"
      10.times do |i|
        s = Selection.new
        s[:selection_text] = params[:selection][i.to_s]
        s[:is_collect] = params[:is_collect].to_i == i ? 1 : 0
        new_selections << s
      end
      quiz[:selections] = new_selections

    elsif params[:question_type] == "2"
      10.times do |i|
        s = Selection.new
        s[:selection_text] = params[:selection2][i.to_s]
        s[:is_collect] = params[:is_collect2][i.to_s] == "on" ? 1 : 0
        new_selections << s
      end
      quiz[:selections] = new_selections

    elsif params[:question_type] == "3"
        quiz[:y_or_n] = params[:is_collect3].to_i
    elsif params[:question_type] == "4"
      old_answer = Answer.find(:first, :conditions => ["question_id = ?", params[:question_id]]).answer_text
      a = Answer.new
      a.answer_text = params[:answer_ta]
      a.user_id = current_user.id
      quiz[:answer] = a
    else
      raise("must not happend")
    end

    old_desctiprion = Description.find(:first, :conditions => ["question_id = ?", params[:question_id]]).description_text
    d = Description.new
    d.description_text = params[:description_ta]
    quiz[:description] = d

    @question = Question.find(params[:question_id])
    @question.attributes = quiz

    if @question.save
      render :update do |page|
        page.redirect_to :controller => "mypage"
      end
    else
      @msgs = @question.errors.full_messages

      # 編集前に戻す処理
      if @question.question_type == 1 || @question.question_type == 2
        i = 0
        @question.selections.each do |selection|
          selection.update_attribute(:selection_text, old_selections[i]["text"])
          selection.update_attribute(:is_collect, old_selections[i]["is_collect"])
          i += 1
        end
      elsif @question.question_type == 4
        @question.answer.update_attribute(:answer_text, old_answer)
      end
      @question.description.update_attribute(:description_text, old_desctiprion)
      

      render :update do |page|
        page.visual_effect :ScrollTo,
                           'container',
                           :duration => 0.15
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end
  
  # TODO: deleteとdestoryはどっちがいいかを検討する
  def destroy
    @question = Question.find(params[:id])
    if @question.user_id != current_user.id
      redirect_to :action => "quiz", :question_id => params[:id]
    else
      if @question.answer
        @question.answer.destroy
      end
      @question.selections.delete_all()

      QuestionExam.delete_all(["question_id = ?", params[:id].to_i])
      QuestionBook.delete_all(["question_id = ?", params[:id].to_i])
      Bookmark.delete_all(["question_id = ?", params[:id].to_i])

      @question.destroy
      @title = ' - マイページ'
      flash[:notice] = "問題を削除しました。"
      redirect_to :controller => "mypage"
    end
  end
  
  def add_book
    if params[:add_book_to] != "" and params[:add_book_to] != "new"
      book = Book.find(params[:add_book_to])
      question = Question.find(params[:id])
      if book.questions.include?(question)
        flash[:notice] = "登録済みです。"
        render :update do |page|
          page.replace_html("add_book_message", :partial=>"message",:locals => {:flug => false})
          page.visual_effect :Opacity,
                             "add_book_message",
                             :from => 1,
                             :to => 0,
                             :duration => 3
        end
      else
        book.questions << question
        flash[:notice] = "登録しました！"
        render :update do |page|
          page.replace_html("add_book_message", :partial=>"message",:locals => {:flug => true})
          page.visual_effect :Opacity,
                             "add_book_message",
                             :from => 1,
                             :to => 0,
                             :duration => 3
        end
      end
    else
      flash[:notice] = "ブックを選択してください。"
      render :update do |page|
        page.replace_html("add_book_message", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                            "add_book_message",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    end
  end
  
  def new_book
    @book = Book.new
  end
  

  def create_book
    @book = Book.new(params[:book])
    @book.user_id = current_user.id
    @book.is_smart = 0

    if @book.name != "自分で登録した問題"
      if @book.save
        my_book = MyBook.new
        my_book.book_id = @book.id
        my_book.user_id = current_user.id
        my_book.save
        render :update do |page|
          page << "len = window.opener.document.getElementById('add_book_to').options.length;"
          page << "window.opener.document.getElementById('add_book_to').options.length++;"
          page << "window.opener.document.getElementById('add_book_to').options[len].text = \"#{@book.name}\";"
          page << "window.opener.document.getElementById('add_book_to').options[len].value = #{@book.id};"
          page << "window.opener.document.getElementById('add_book_to').selectedIndex = len;"
          page << "window.close();"
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


  def on_bookmark
    @question = Question.find(params[:id])
    unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
      bookmark = Bookmark.new
      bookmark.question_id = params[:id]
      bookmark.user_id = current_user.id
      bookmark.save
    end
    @is_bookmark = true
    render :partial => 'bookmark'
  end

  def off_bookmark
    @question = Question.find(params[:id])
    if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
      bookmark.destroy
    end
    @is_bookmark = false
    render :partial => 'bookmark'
  end

  def evaluation_in
    @question = Question.find(params[:question_id].to_i)
    @eval = Evaluation.new
    @eval.question_id = params[:question_id].to_i
    @eval.user_id = current_user.id
    @eval.point = params[:id].to_i
    @eval.save
    evals = Evaluation.find(:all,:conditions => ["question_id = ?",params[:question_id].to_i])
    @count = evals.size
    @sum = 0
    evals.each do |eval|
      @sum+=eval.point
    end
    @avg = @sum/evals.size
    render :update do |page|
      page.replace_html("evaluation_box", :partial=>"evals",:object => {:sum => @sum, :avg => @avg})
      page.visual_effect :highlight,
                             "sum_and_avg",
                             :startcolor => "#ffd900",
                             :endcolor => "#ffffff",
                             :duration => 1.5

    end
  end
  
  def report
    @id = params[:id].to_i
  end
  
  def report_send
    @report = Report.new
    if logged_in?
      @report.user_id = current_user.id
    end
    @report.question_id = params[:id]
    @report.description = params[:report_text]
    if @report.save
      render :update do |page|
        page.remove("description_box")
        page.remove("submit_box")
        page.remove("message")
        page.show("navi")
        page.show("thanks")
      end
    else
      @msgs = @report.errors.full_messages
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
