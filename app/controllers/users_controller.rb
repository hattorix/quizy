class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  

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
      render :update do |page|
        page.redirect_to :controller => "mypage"
      end
      flash[:notice] = "Thanks for signing up!"
    else
      @msgs =  @user.errors.full_messages
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

  def activate_all
    users = User.find(:all,["activated_at = ?",nil])
    users.each do |user|
      user.update_attribute("activated_at", Time.now)
    end
    redirect_back_or_default('/')
  end


  def update
    @user = current_user
    if !User.authenticate(current_user.login, params[:old_password])
      @user.valid?
      @msgs =  @user.errors.full_messages
      @msgs << "パスワードが違います。"
      render :update do |page|
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    else
    @user.update_attributes(params[:user])
      if @user.errors.empty?
        render :update do |page|
          page.redirect_to :controller => "mypage"
        end
        flash[:notice] = "Thanks for signing up!"
      else
        @msgs =  @user.errors.full_messages
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
