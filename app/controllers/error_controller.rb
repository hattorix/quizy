class ErrorController < ApplicationController
  def error
    if @message = params[:message]
    else
      @message = "エラーが発生しました。"
    end
  end
  
  def mail_error
  @message = "メール送信に失敗しました。"
  render :action => "error"
  end
end
