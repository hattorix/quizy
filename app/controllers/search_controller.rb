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

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10
    # 付箋を調べる
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

    render :action => :index
  end

  def tag
    @id = params[:id]
    @results = Question.find_tagged_with(params[:id])
    @flg = 0
    @type = "タグ"
    @result_text = "『#{params[:id]}』タグの問題"

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    # 付箋を調べる
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

      result_ids = Array.new
      @results.each do |result|
        result_ids << result.id
      end

      #ページング
      if @flg == 0            #問題検索
        @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10
        # 付箋を調べる
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
      elsif @flg == 1         #タグ検索
        @results = Tag.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      elsif @flg == 2         #ブック検索
        @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      elsif @flg == 3         #テスト検索
        @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10
      end

      render :action => :index
    else
        flash[:notice] = "キーワードを入力してください。"
        render :update do |page|
          page.replace_html("message", :partial=>"message",:locals => {:flug => false})
          page.visual_effect :Opacity,
                             "message",
                             :from => 1,
                             :to => 0,
                             :duration => 3
        end
#      redirect_to :controller => :top
    end
  end
  
  def add_book
    if params[:add_book_to] != "" and params[:add_book_to] != "new"
      if params[:to_add_book]
        book = Book.find(params[:add_book_to])
        i = 0
        params[:to_add_book].each do |question_id|
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
        flash[:notice] = "問題を選択してください。"
        flug = false
      end
    else
      flash[:notice] = "ブックを選択してください。"
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

  def users_question
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Question.find(:all, :conditions => ["user_id = ? and is_public = 1",user.id])
    @result_text = "#{params[:id]}の問題"
    @flg = 0
    @user_name = params[:id]

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Question.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  def users_book
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Book.find(:all, :conditions => ["user_id = ? and is_public = 1",user.id])
    @result_text = "#{params[:id]}のブック"
    @flg = 2
    @user_name = params[:id]

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
  end

  def users_exam
    user = User.find(:first, :conditions => ["login = ?",params[:id]])
    @results = Exam.find(:all, :conditions => ["user_id = ? and is_public = 1 ",user.id])
    @result_text = "#{params[:id]}のテスト"
    @flg = 3
    @user_name = params[:id]

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index
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
    ids = params[:id].split("/")
    # 問題単の場合
    if ids.size == 1
      @question = Question.find(params[:id])
      unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
        bookmark = Bookmark.new
        bookmark.question_id = params[:id]
        bookmark.user_id = current_user.id
        bookmark.save
      end

      @results = params[:results].split("/").flatten!
      bookmarks = Array.new
      @results.each do |result|
        bookmarks << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                             result.to_i,
                                                             current_user.id])
      end
      bookmarks.compact!
      @is_bookmark_all = true if bookmarks.size == @results.size

      render :update do |page|
        page.replace_html("bookmark#{params[:id]}", :partial=>"bookmark", :locals =>{:is_bookmark => true,:question_id => params[:id],:results => @results})
        page.replace_html("bookmark", :partial=>"bookmark", :locals =>{:is_bookmark => @is_bookmark_all,:question_id => @results})
      end
    # 全問題の場合
    else
      ids.each do |id|
        @question = Question.find(id.to_i)
        unless Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",id.to_i,current_user.id])
          bookmark = Bookmark.new
          bookmark.question_id = id.to_i
          bookmark.user_id = current_user.id
          bookmark.save
        end
      end
      render :update do |page|
        ids.each do |id|
          page.replace_html("bookmark#{id.to_i}", :partial=>"bookmark", :locals =>{:is_bookmark => true,:question_id => id.to_i,:results => ids})
        end
        page.replace_html("bookmark", :partial=>"bookmark", :locals =>{:is_bookmark => true,:question_id => ids})
      end
    end
  end

  def off_bookmark
    ids = params[:id].split("/")
    # 問題単の場合
    if ids.size == 1
      @question = Question.find(params[:id])
      if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",params[:id],current_user.id])
        bookmark.destroy
      end

      @results = params[:results].split("/").flatten!
      bookmarks = Array.new
      @results.each do |result|
        bookmarks << Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",
                                                             result.to_i,
                                                             current_user.id])
      end
      bookmarks.compact!
      @is_bookmark_all = true if bookmarks.size == @results.size

      render :update do |page|
        page.replace_html("bookmark#{params[:id]}", :partial=>"bookmark", :locals =>{:question_id => params[:id],:results => @results})
        page.replace_html("bookmark", :partial=>"bookmark", :locals =>{:is_bookmark => @is_bookmark_all,:question_id => @results})
      end
    # 全問題の場合
    else
      ids.each do |id|
        @question = Question.find(id.to_i)
        if bookmark = Bookmark.find(:first, :conditions => ["question_id = ? and user_id = ?",id.to_i,current_user.id])
          bookmark.destroy
        end
      end
      render :update do |page|
        ids.each do |id|
          page.replace_html("bookmark#{id.to_i}", :partial=>"bookmark", :locals =>{:question_id => id.to_i,:results => ids})
        end
        page.replace_html("bookmark", :partial=>"bookmark", :locals =>{:question_id => ids})
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
    q = Question.find(params[:id])
    @result_text = "『#{q.question_text}』を含むブック"

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

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
    q = Question.find(params[:id])
    @result_text = "『#{q.question_text}』を含むテスト"

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Exam.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index

  end
  
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

    result_ids = Array.new
    @results.each do |result|
      result_ids << result.id
    end
    @results = Book.paginate_by_id result_ids, :page => params[:page], :per_page => 10

    render :action => :index

  end

  def add_mybook
    if MyBook.find(:all,:conditions=>["book_id = ? and user_id = ?",params[:id],current_user.id]).size == 0
      mybook = MyBook.new
      mybook.book_id = params[:id]
      mybook.user_id = current_user.id
      mybook.save
      flash[:notice] = "登録しました！"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    else
      flash[:notice] = "登録済みです。"
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
      flash[:notice] = "登録しました！"
      render :update do |page|
        page.replace_html("add_mycontents_message#{params[:id]}", :partial=>"message",:locals => {:flug => true})
        page.visual_effect :Opacity,
                           "add_mycontents_message#{params[:id]}",
                            :from => 1,
                            :to => 0,
                            :duration => 3
      end
    else
      flash[:notice] = "登録済みです。"
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

end
