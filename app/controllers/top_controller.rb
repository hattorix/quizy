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
end