class UserMailer < ActionMailer::Base
def signup_notification(user)
  setup_email(user)
  @subject    += '仮登録完了のお知らせ'
  @body[:url] = "http://localhost:3000/activate/#{user.activation_code}" # テストサーバのURLにあわせて
end
  
  def activation(user)
    setup_email(user)
    @subject    += '本登録完了のお知らせ'
    @body[:url]  = "http://localhost:3000/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "master@quizy.co.jp"
      @subject     = "[Quizy] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
