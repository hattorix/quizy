# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  layout "application" 

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '1e292eca6c92091a1b98e86540f1bc8d'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
=begin
  rescue_from ActionController::RoutingError do |exception|
    render :xml => exception, :status => 404
  end
  # モデルオブジェクトが見つからない場合は404エラーを返す
  rescue_from ActiveRecord::RecordNotFound do |exception|
    render :xml => exception, :status => 404
  end
 
  protected
 
  def deny_access(exception)
  end
 
  def show_errors(exception)
  end
=end
  def rescue_action( excptn )
    redirect_to :action => 'error', :controller => "/error"
  end

end
