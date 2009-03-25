class SearchController < ApplicationController

  layout :select_layout

  def select_layout
    if %w(new_book).include?(action_name)
    else
      "application"
    end
  end

  def category
    @id = params[:id]
    @results = Question.find(:all, :conditions => ['category_id = ? and is_public = 1', params[:id]])
    category = Category.find(params[:id])
#    render :partial => 'results', :collection => results
    @flg = 0
    @type = "カテゴリ"
    @result_text = "『#{category.name}』カテゴリの問題"
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end

    all_bookmarks()

    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    bookmarks()

    render :action => :index
  end

  def tag
    @id = params[:id]
    @results = Question.find_tagged_with(params[:id])
    @flg = 0
    @type = "タグ"
    @result_text = "『#{params[:id]}』タグの問題"
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results

    all_bookmarks()

    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    bookmarks()

    render :action => :index
  end

  def text
    @conditions = params[:conditions]
    @searchtype = params[:searchtype]
    keywords = params[:conditions].split(/\s|　/)
    if keywords.size > 0
      @results_hash = Hash.new
      @results = Array.new
      @result_text = Array.new
      @flg = params[:search_for].to_i
      i = 0
      keywords.compact!
      keywords.each do |keyword|
        if @flg == 0            #問題検索
          @results_hash[i] = Question.find(:all, :conditions => ['question_text like ? and is_public = 1', "%#{keyword}%"])
          @result_text << "\"#{keyword}\""
          @type = "問題"
        elsif @flg == 1         #タグ検索
          @results_hash[i] = Tag.find(:all, :conditions => ['name like ?', "%#{keyword}%"])
          @result_text << "\"#{keyword}\""
          @type = "タグ"
        elsif @flg == 2         #ブック検索
          @results_hash[i] = Book.find(:all, :conditions => ['(name like ? or outline like ?) and is_public = 1 ', "%#{keyword}%","%#{keyword}%"])
          @result_text << "\"#{keyword}\""
          @type = "ブック"
        elsif @flg == 3         #テスト検索
          @results_hash[i] = Exam.find(:all, :conditions => ['name like ? and is_public = 1', "%#{keyword}%"])
          @result_text << "\"#{keyword}\""
          @type = "テスト"

        end
        i += 1
      end
      @results = @results_hash[0]

      # キーワードが複数の場合
      if keywords.size >= 2
        # and検索
        if params[:searchtype] == "and"
          (@results_hash.size-1).times do |i|
            @results = (@results & @results_hash[i+1]) 
          end
          @results.uniq!
          @result_text << "の全てを含む"
        # or検索
        else
          (@results_hash.size-1).times do |i|
            @results = @results.concat(@results_hash[i+1])
          end
          @results.uniq!
          @result_text << "のいずれかを含む"
        end
      else
        @result_text << "を含む"
      end

      @result_text << @type
      @result_text.join("")

      if params[:add_book_all]
        @add_book_all = params[:add_book_all]
      else
        @add_book_all = "false"
      end


      result_ids = Array.new
      @results.each do |result|
        result_ids << result.id
      end

      #ページング
      if @flg == 0            #問題検索
        @results_all = @results

        all_bookmarks()

        @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

        bookmarks()

      elsif @flg == 1         #タグ検索
        @results_all = @results
        @results = Tag.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      elsif @flg == 2         #ブック検索
        @results_all = @results
        @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      elsif @flg == 3         #テスト検索
        @results_all = @results
        @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      end

      render :action => :index
    else
      flash.now[:notice] = "キーワードを入力してください。"
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                            "message",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    end
  end

  #問題検索（ユーザー）
  def users_question
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Question.find(:all, :conditions => ["user_id = ? and is_public = 1",user.id])
    @result_text = "#{params[:id]}の問題"
    @flg = 0
    @user_name = params[:id]
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  #ブック検索（ユーザー）
  def users_book
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Book.find(:all, :conditions => ["user_id = ? and is_public = 1",user.id])
    @result_text = "#{params[:id]}のブック"
    @flg = 2
    @user_name = params[:id]
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  #テスト検索（ユーザー）
  def users_exam
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Exam.find(:all, :conditions => ["user_id = ? and is_public = 1 ",user.id])
    @result_text = "#{params[:id]}のテスト"
    @flg = 3
    @user_name = params[:id]
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  #ブック検索（問題）
  def search_book
    @results = Array.new
    book_questions = QuestionBook.find(:all, :conditions => ["question_id = ?",params[:id]])
    book_questions.each do |book_question|
      if book = Book.find(:first, :conditions => ["id = ? and is_public = 1",book_question.book_id])
        @results << book
      end
    end
    @flg = 2
    q = Question.find(params[:id])
    @result_text = "『#{q.question_text}』を含むブック"
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  #テスト検索（問題）
  def search_exam
    @results = Array.new
    exam_questions = QuestionExam.find(:all, :conditions => ["question_id = ?",params[:id]])
    exam_questions.each do |exam_question|
      if exam = Exam.find(:first, :conditions => ["id = ? and is_public = 1",exam_question.exam_id])
        @results << exam
      end
    end
    @flg = 3
    q = Question.find(params[:id])
    @result_text = "『#{q.question_text}』を含むテスト"
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  #スマートブック検索
  def search_smart_book
    @id = params[:id]
    if params[:type] == "tag"
      @results = Book.find(:all, :conditions => ["tags like ? and is_public = 1 ","%#{params[:id]}%"])
      @flg = 2
      @type = "タグ"
      @result_text = "『#{params[:id]}』タグを含むスマートブック"
    elsif params[:type] == "category"
      category = Category.find(params[:id])
      @results = Book.find(:all, :conditions => ["categories like ? and is_public = 1 ","%#{category.name}%"])
      @flg = 2
      @type = "カテゴリ"
      @result_text = "『#{category.name}』カテゴリを含むスマートブック"
    end
    if @add_book_all = params[:add_book_all]
      @add_book_all = "false"
    end

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results_all = @results
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end



  def on_bookmark
    # 問題単の場合
    if params[:type] == "single"
      unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
        bookmark = Bookmark.new
        bookmark.question_id = params[:id]
        bookmark.user_id = current_user.id
        bookmark.save
      end

      #ページ内の全ブックマークを確認
      bookmarks = Array.new
      params[:questions].each do |question|
        bookmarks << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                             question.to_i,
                                                             current_user.id])
      end
      bookmarks.compact!
      @is_bookmark_all = true if bookmarks.size == params[:questions].size

      #全ページの全ブックマークを確認
      bookmark_all = Array.new
      params[:all_questions].each do |question|
        bookmark_all << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                             question.to_i,
                                                             current_user.id])
      end
      bookmark_all.compact!
      @is_bookmark_all_page = true if bookmark_all.size == params[:all_questions].size

      render :update do |page|
        page.replace_html("bookmark#{params[:id]}", :partial=>"bookmark", :locals =>{:is_bookmark => true,
                                                                                       :question_id => params[:id],
                                                                                       :questions => params[:questions],
                                                                                       :all_questions => params[:all_questions],
                                                                                       :type => "single"})
        page.replace_html("bookmark_all", :partial=>"bookmark", :locals =>{:is_bookmark => @is_bookmark_all,
                                                                            :question_id => params[:questions],
                                                                            :questions => params[:questions],
                                                                            :all_questions => params[:all_questions],
                                                                            :type => "all"})
        page.replace_html("bookmark_all_page", :partial=>"bookmark", :locals =>{:is_bookmark => @is_bookmark_all_page,
                                                                                 :question_id => params[:all_questions],
                                                                                 :questions => params[:questions],
                                                                                 :all_questions => params[:all_questions],
                                                                                 :type => "all_page"})
      end
    else

      # ページ内全問題の場合
      if params[:type] == "all"
        params[:questions].each do |question|
          unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",question.to_i,current_user.id])
            bookmark = Bookmark.new
            bookmark.question_id = question.to_i
            bookmark.user_id = current_user.id
            bookmark.save
          end
        end

        #全ページの全ブックマークを確認
        bookmark_all = Array.new
        params[:all_questions].each do |question|
          bookmark_all << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                               question.to_i,
                                                               current_user.id])
        end
        bookmark_all.compact!
        @is_bookmark_all_page = true if bookmark_all.size == params[:all_questions].size
      # 全ページの問題の場合
      elsif params[:type] == "all_page"
        params[:all_questions].each do |question|
          unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",question.to_i,current_user.id])
            bookmark = Bookmark.new
            bookmark.question_id = question.to_i
            bookmark.user_id = current_user.id
            bookmark.save
          end
        end
        @is_bookmark_all_page = true
      end
      render :update do |page|
        params[:questions].each do |question|
          page.replace_html("bookmark#{question.to_i}", :partial=>"bookmark", :locals =>{:is_bookmark => true,
                                                                                           :question_id => question.to_i,
                                                                                           :questions => params[:questions],
                                                                                           :all_questions => params[:all_questions],
                                                                                           :type => "single"})
        end
        page.replace_html("bookmark_all", :partial=>"bookmark", :locals =>{:is_bookmark => true,
                                                                            :question_id => params[:questions],
                                                                            :questions => params[:questions],
                                                                            :all_questions => params[:all_questions],
                                                                            :type => "all"})
        page.replace_html("bookmark_all_page", :partial=>"bookmark", :locals =>{:is_bookmark => @is_bookmark_all_page,
                                                                                 :question_id => params[:all_questions],
                                                                                 :questions => params[:questions],
                                                                                 :all_questions => params[:all_questions],
                                                                                 :type => "all_page"})
      end
    end
  end

  def off_bookmark
    # 問題単の場合
    if params[:type] == "single"
      if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
        bookmark.destroy
      end
      render :update do |page|
        page.replace_html("bookmark#{params[:id]}", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                                       :question_id => params[:id],
                                                                                       :questions => params[:questions],
                                                                                       :all_questions => params[:all_questions],
                                                                                       :type => "single"})
        page.replace_html("bookmark_all", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                            :question_id => params[:questions],
                                                                            :questions => params[:questions],
                                                                            :all_questions => params[:all_questions],
                                                                            :type => "all"})
        page.replace_html("bookmark_all_page", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                                 :question_id => params[:all_questions],
                                                                                 :questions => params[:questions],
                                                                                 :all_questions => params[:all_questions],
                                                                                 :type => "all_page"})
      end
    else
      # ページ内全問題の場合
      if params[:type] == "all"
        params[:questions].each do |question|
          if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",question.to_i,current_user.id])
            bookmark.destroy
          end
        end
      # 全ページの問題の場合
      elsif params[:type] == "all_page"
        params[:all_questions].each do |question|
          if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",question.to_i,current_user.id])
            bookmark.destroy
          end
        end
      end
      render :update do |page|
        params[:questions].each do |question|
          page.replace_html("bookmark#{question.to_i}", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                                           :question_id => question.to_i,
                                                                                           :questions => params[:questions],
                                                                                           :all_questions => params[:all_questions],
                                                                                           :type => "single"})
        end
        page.replace_html("bookmark_all", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                            :question_id => params[:questions],
                                                                            :questions => params[:questions],
                                                                            :all_questions => params[:all_questions],
                                                                            :type => "all"})
        page.replace_html("bookmark_all_page", :partial=>"bookmark", :locals =>{:is_bookmark => false,
                                                                                 :question_id => params[:all_questions],
                                                                                 :questions => params[:questions],
                                                                                 :all_questions => params[:all_questions],
                                                                                 :type => "all_page"})
      end
    end
  end

  def add_book
    if params[:add_book_to] != "" and params[:add_book_to] != "new"
      if params[:to_add_book]
        book = Book.find(params[:add_book_to])
        i = 0
        if params[:to_add_book_all] == "true"
          params[:results_all].each do |question_id|
            question = Question.find(question_id.to_i)
            unless book.questions.include?(question)
              book.questions << question
              i += 1
            end
          end
        else
          params[:to_add_book].each do |question_id|
            question = Question.find(question_id.to_i)
            unless book.questions.include?(question)
              book.questions << question
              i += 1
            end
          end
        end
        if i == 0
          flash.now[:notice] = "全て登録済みです。"
          flug = false
        else
          flash.now[:notice] = "#{i}件登録しました！"
          flug = true
        end
      else
        flash.now[:notice] = "問題を選択してください。"
        flug = false
      end
    else
      flash.now[:notice] = "ブックを選択してください。"
      flash.keep(:notice)
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

  def add_mybook
    if MyBook.find(:all,:conditions=>["book_id = ? and user_id = ?",params[:id],current_user.id]).size == 0
      mybook = MyBook.new
      mybook.book_id = params[:id]
      mybook.user_id = current_user.id
      mybook.save
      flash.now[:notice] = "登録しました！"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    else
      flash.now[:notice] = "登録済みです。"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                            "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    end
  end

  def add_myexam
    if MyExam.find(:all,:conditions=>["exam_id = ? and user_id = ?",params[:id],current_user.id]).size == 0
      myexam = MyExam.new
      myexam.exam_id = params[:id]
      myexam.user_id = current_user.id
      myexam.save
      flash.now[:notice] = "登録しました！"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    else
      flash.now[:notice] = "登録済みです。"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => false})
        page.visual_effect :Opacity,
                            "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    end
  end



  private

  # 全ての付箋を調べる
  def all_bookmarks()
    @results_all = @results

    all_bookmarks = Array.new
    @results.each do |result|
      all_bookmarks << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                              result.id,
                                                              current_user.id])
    end
    all_bookmarks.compact!
    @is_bookmark_all_page = true if all_bookmarks.size == @results_all.size
  end

  # ページ内付箋を調べる
  def bookmarks()
    bookmarks = Array.new
    if logged_in?
      @results.each do |result|
        bookmarks << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                            result.id,
                                                            current_user.id])
      end
      bookmarks.compact!
      @is_bookmark_all = true if bookmarks.size == @results.size
    end
  end
end
