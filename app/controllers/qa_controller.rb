class QaController < ApplicationController

  def new
    # プルダウンの初期化
    @categories = Category.find(:all, :order => 'id')
    @question_types = QuestionType.find(:all, :order => 'id')
  end

  def create
    # Question
    @q = Question.new
    @q.question_type = params[:question_type]
    @q.question_text = params[:question_ta].gsub("\n", "<br />")
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
    d.description_text = params[:description_ta].gsub("\n", "<br />")
    d.question_id = @q.id
    d.user_id = current_user.id
    @q.description = d

    # コミット 
    if @q.save
       book = Book.find(:first,:conditions => ["name = '自分で登録した問題' and user_id =? ", current_user.id])
       book.questions << @q
      if params[:name] == 'submit1'
        render :update do |page|
          page << 'mypage()'
        end
      else
        render :update do |page|
          page << 'reload()'
          page.visual_effect :ScrollTo,
                             'container',
                             :duration => 0
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
      @books = Book.find(:all, :conditions => ["user_id = ? and name != '自分で登録した問題'", current_user.id])
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
          @result_text = "× 残念です！"
          @is_collect = "0"
          @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
          @question.save
        end
      else
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
        @result_text = "× 残念です！"
        @is_collect = "0"
        @question.update_attribute("wrong_count", @question.wrong_count.to_i + 1)
        @question.save
     end
    else
      raise("must not happend")
    end
    evals = Evaluation.find(:all,:conditions => ["question_id = ?",@question.id])
    @sum = 0
    @avg = 0
    if evals.size > 0
      evals.each do |eval|
        @sum+=eval.point
      end
      @avg = @sum/evals.size
    end
  end

  def edit
    question_id = params[:id]
    @question = Question.find(question_id)
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
    quiz[:question_type] = params[:question_type].gsub("\n", "<br />")
    quiz[:category_id] = params[:category]
    quiz[:tag_list] = params[:tag]
    selections = Selection.find(:all, :conditions => ["question_id = ?", params[:question_id]])
    old_selections = []
    selections.each do |selection|
      old_selections << selection
    end

    new_selections = Array.new

    if params[:question_type] == "1"
      selections.each do |selection|
        s = selection.new
        s[:selection_text] = params["selection"][selection.id.to_s]
        s[:is_collect] = params["is_collect"] == [selection.id] ? 1 : 0
        selection.update_attributes(s)
      end

    elsif params[:question_type] == "2"
      selections.each do |s|
        new_selection = Selection.new
        new_selection.selection_text = params[:selection2][s.id.to_s]
        new_selection.is_collect = params[:is_collect2][s.id.to_s] == "on" ? 1 : 0
        new_selection.user_id = current_user.id
        new_selections << new_selection
      end
      quiz[:selections] = new_selections

    elsif params[:question_type] == "3"
        quiz[:y_or_n] = params[:is_collect3].to_i
    elsif params[:question_type] == "4"
        a = Answer.new
        a.answer_text = params[:answer_ta].gsub("\n", "<br />")
        a.user_id = current_user.id
        quiz[:answer] = a
    else
      # TODO: レコード数を調べて、0件だったら追加する処理
    end

    d_text = Description.find(:first, :conditions => ["question_id = ?", params[:question_id]]).description_text
    d = Description.new
    d.description_text = params[:description_ta].gsub("\n", "<br />")
    quiz[:description] = d

        @question = Question.find(params[:question_id])
        @question.attributes = quiz

    if @question.save
      render :update do |page|
        page << 'mypage()'
      end
    else
      @question.update_attributes({:selections => old_selections})
      @msgs = @question.errors.full_messages


      render :update do |page|
        page << 'top()'
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 10.5
      end
    end
  end
  
  # TODO: deleteとdestoryはどっちがいいかを検討する
  def destroy
    @question = Question.find(params[:id])
    if @question.answer
      @question.answer.destroy
    end
    @question.selections.delete_all()

    QuestionExam.delete_all(["question_id = ?", params[:id].to_i])
    QuestionBook.delete_all(["question_id = ?", params[:id].to_i])    

    @question.destroy
    @title = ' - マイページ'
    redirect_to :controller => 'mypage'
  end
  
  def add_book
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
  end
=begin
  def evalchange_on
    render :update do |page|
      params[:id].to_i.times do |i|
        page.replace_html("eval".concat(i.to_s),"<img src='../images/hosi_on.gif'>")
      end
    end
  end

  def evalchange_off
    render :update do |page|
      10.times do |i|
        page.replace_html("eval".concat(i.to_s),"<img src='../images/hosi_off.gif'>")
      end
    end
  end
=end

  def evaluation_in
    @question = Question.find(params[:question_id].to_i)
    @eval = Evaluation.new
    @eval.question_id = params[:question_id].to_i
    @eval.user_id = current_user.id
    @eval.point = params[:id].to_i
    @eval.save
    evals = Evaluation.find(:all,:conditions => ["question_id = ?",params[:question_id].to_i])
    @sum = 0
    evals.each do |eval|
      @sum+=eval.point
    end
    @avg = @sum/evals.size
    render :update do |page|
      page.replace_html("evaluation", :partial=>"evals",:object => {:sum => @sum, :avg => @avg})
      page[:sum_and_avg].visual_effect :highlight,
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
