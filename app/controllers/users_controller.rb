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
    if @user.password != params[:password]
      flash[:notice] = "パスワードが違います。"
            render :action => 'edit'
    else
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
  end

end
