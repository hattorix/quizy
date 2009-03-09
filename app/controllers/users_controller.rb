class UsersController < ApplicationController
  def index
    if logged_in?
      redirect_to :controller => :mypage
    end
  end
  # render new.rhtml
  def new
  end
  
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      self.current_user = @user
      book = Book.new
      book.name = "自分で登録した問題"
      book.is_public = 2
      book.user_id = @user.id
      book.save
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!"
    else
      render :action => 'new'
    end
  end

  def remember_me
    remember_me_for 2.weeks
  end

  def edit
  end

  def update
    @user = current_user
    if !User.authenticate(current_user.login, params[:old_password])
      flash[:notice] = "パスワードが違います。"
            render :action => 'edit'
    else
    @user.update_attributes(params[:user])
      if @user.errors.empty?
        redirect_back_or_default('/')
        flash[:notice] = "Thanks for signing up!"
      else
        render :action => 'edit'
      end
    end
  end

  def delete
    Bookmark.delete_all(["user_id = ?", current_user.id])
    History.delete_all(["user_id = ?", current_user.id])
    ExamTemp.delete_all(["user_id = ?", current_user.id])
    MyBook.delete_all(["user_id = ?", current_user.id])
    MyExam.delete_all(["user_id = ?", current_user.id])
    Book.delete_all(["user_id = ? and name = '自分で登録した問題'", current_user.id])
    current_user.destroy

    redirect_back_or_default('/')
  end

end
