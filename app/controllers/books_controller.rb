class BooksController < ApplicationController
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
  end

  # GET /books/new
  # GET /books/new.xml
  def new
    @book = Book.new
  end

  def edit
    @book = Book.find(params[:id])
  end

  def create
    @book = Book.new(params[:book])
    @book.user_id = current_user.id

    if @book.name != "自分で登録した問題"
      if @book.save
        my_book = MyBook.new
        my_book.book_id = @book.id
        my_book.user_id = current_user.id
        my_book.save
        render :update do |page|
          page << 'mypage()'
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
        render :update do |page|
          page << 'mypage()'
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
    mybooks = MyBook.find(:all,["user_id = ?",current_user.id])
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
end
