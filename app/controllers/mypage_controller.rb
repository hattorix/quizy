class MypageController < ApplicationController
  before_filter :login_required
  def index
    # カテゴリ一覧
    @categories = Category.find(:all, :order => 'id')

    # マイブック一覧
    @mybooks = MyBook.find(:all,
                       :limit => 6,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    # マイテスト一覧
    @myexams = MyExam.find(:all,
                       :limit => 4,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    # 最近登録した問題
    @questions = Question.find(:all, :limit => 10, :order => "created_at desc",
                               :conditions => ['user_id = ?', current_user.id])
  end
end