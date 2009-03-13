class UsersController < ApplicationController

  before_filter :login_required, :only =>["edit"]

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  

  # render new.rhtml
  def new
  end

  def send_mail
  end

  def edit
    @reason = ""
    if setting = Setting.find(:first,:conditions => ["user_id = ?",current_user.id])
      @weak_lv_1 = setting.weak_lv_1
      @weak_lv_2 = setting.weak_lv_2
      @weak_lv_3 = setting.weak_lv_3
      @weak_lv_4 = setting.weak_lv_4
      @weak_lv_5 = setting.weak_lv_5
    else
      @weak_lv_1 = 99
      @weak_lv_2 = 80
      @weak_lv_3 = 70
      @weak_lv_4 = 60
      @weak_lv_5 = 50
    end
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
      book = Book.new
      book.name = "自分で登録した問題"
      book.is_public = 2
      book.user_id = @user.id
      book.save
      setting = Setting.new
      setting.user_id = @user.id
      setting.weak_lv_1 = 99
      setting.weak_lv_2 = 80
      setting.weak_lv_3 = 70
      setting.weak_lv_4 = 60
      setting.weak_lv_5 = 50
      setting.save
      render :update do |page|
        page.redirect_to (:action => "send_mail", :method => :get)
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
    redirect_to :controller => "mypage"
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
      @msgs << "パスワードが違います。#{params[:old_password]}"
      render :update do |page|
        page.show("message")
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
          page.show("message")
          page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
          page[:msg].visual_effect :highlight,
                                    :startcolor => "#ffd900",
                                    :endcolor => "#ffffff",
                                    :duration => 1.5
        end
      end
    end
  end

  def update_weak
    if @setting = Setting.find(:first,:conditions => ["user_id = ?",current_user.id])
      @setting.update_attributes("weak_line" => params[:weak_line].to_i)
    else
      @setting = Setting.new
      @setting.user_id = current_user.id
      @setting.weak_lv_1 = params[:weak_lv_1].to_i
      @setting.weak_lv_2 = params[:weak_lv_2].to_i
      @setting.weak_lv_3 = params[:weak_lv_3].to_i
      @setting.weak_lv_4 = params[:weak_lv_4].to_i
      @setting.weak_lv_5 = params[:weak_lv_5].to_i
      @setting.save
    end
    if @setting.errors.empty?
      render :update do |page|
        page.redirect_to :controller => "mypage"
      end
      flash[:notice] = "Thanks for signing up!"
    else
      @msgs =  @user.errors.full_messages
      render :update do |page|
        page.show("message")
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    end
  end

  def check_delete
    if !User.authenticate(current_user.login, params[:password][0])
      @msgs = Array.new
      @msgs << "パスワードが違います。"
      render :update do |page|
        page.show("message")
        page.replace_html("message", :partial=>"message",:locals => {:flug => "error"},:object => @msgs)
        page[:msg].visual_effect :highlight,
                                  :startcolor => "#ffd900",
                                  :endcolor => "#ffffff",
                                  :duration => 1.5
      end
    else
      render :update do |page|
        page.hide("message")
        page.hide("secession_form_1")
        page.show("secession_form_2")
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

    redirect_to secession_path
  end
  
  def secession
  end
end
