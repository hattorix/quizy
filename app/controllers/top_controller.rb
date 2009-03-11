class TopController < ApplicationController
  def index
    # カテゴリ一覧
    @categories = Category.find(:all, :order => 'id')
    # 新着問題
    @new_questions = Question.find(:all, :conditions => ["is_public = 1"], :order => 'created_at desc', :limit => '10')
    # 新着ブック
    @new_books = Book.find(:all, :conditions => ["is_public = 1"], :order => 'created_at desc', :limit => '10')
    # 出題数ランキング
    @rank_questions = Question.find(:all, :conditions => ["is_public = 1"], :order => 'question_count desc', :limit => '10')
  end
  
  # render new.rhtml
  def new
  end

  def activate_all
    users = User.find(:all,["activated_at = ?",nil])
    users.each do |user|
      user.update_attribute("activated_at = ?", Time.now)
    end
    redirect_to :controller => "top", :action => "index"
  end
end