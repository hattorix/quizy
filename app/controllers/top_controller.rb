class TopController < ApplicationController
  def index
    # カテゴリ一覧
    @categories = Category.find(:all, :order => 'id')
    # 新着問題
    @new_questions = Question.find(:all, :conditions => ["is_public = 1"], :order => 'created_at desc', :limit => '10')
    # 新着ブック
    @new_books = Book.find(:all, :conditions => ["is_public = 1"], :order => 'created_at desc', :limit => '10')
    # 週間出題数ランキング
    count_in_week = History.find(:all, :conditions => ["? >= created_at and created_at >= ?",Time.now,1.week.ago])
    rank_in_week = count_in_week.group_by(&:question_id)
    rank_in_week.sort! do |a,b|
      b[1].size <=> a[1].size
    end
    @rank_questions = Array.new
    rank_in_week.each do |question|
      if q = Question.find(:first,:conditions => ["id = ? and is_public = 1",question[0]])
        @rank_questions << [q,question[1].size]
      end
      if @rank_questions.size == 10
        break
      end
    end
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