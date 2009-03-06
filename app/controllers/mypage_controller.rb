class MypageController < ApplicationController
  before_filter :login_required
  def index
    # カテゴリ一覧
    @categories = Category.find(:all, :order => 'id')

    # マイブック一覧
    @mybooks = MyBook.find(:all,
                       :limit => 8,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    # マイテスト一覧
    @myexams = MyExam.find(:all,
                       :limit => 8,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    # 最近登録した問題
    @questions = Question.find(:all, :limit => 10, :order => "created_at desc",
                               :conditions => ['user_id = ?', current_user.id])
    # 最近解答した問題
    @histories = History.find(:all, :limit => 10, :order => "created_at desc",
                               :conditions => ['user_id = ?', current_user.id])
  end
  
  def result
    @graph = open_flash_chart_object(850,400, '/mypage/bar_chart', true, '/')     
  end
  def bar_chart
    bar1 = Bar.new(50, '#ff0033')
    bar1.key('正解数', 10)

    bar2 = Bar.new(50, '#0066CC')
    bar2.key('回答数', 10)

    days = Array.new

    30.times do |t|
      y = t.day.ago.strftime("%y")
      m = t.day.ago.strftime("%m")
      d = t.day.ago.strftime("%d")

      first_time = Time.local(y, m, d, 00, 00, 00)
      last_time = Time.local(y, m, d, 23, 59, 59)


      bar1.data << History.count(:conditions => ["created_at > ? and created_at < ? and user_id = ? and correct_or_wrong = 1",
                                                  first_time,
                                                  last_time,
                                                  current_user.id])
      bar2.data << History.count(:conditions => ["created_at > ? and created_at < ? and user_id = ?",
                                                  first_time,
                                                  last_time,
                                                  current_user.id])
      days << last_time.strftime("%m/%d")
    end

    g = Graph.new
    first = 29.day.ago.strftime("%m/%d")
    last = Time.now.strftime("%m/%d")
    g.title("#{first}～#{last}の成績", "{font-size: 26px;}")

    g.data_sets << bar1
    g.data_sets << bar2

    g.set_x_labels(days)
    g.set_x_label_style(10, '#000000', 1, 1)
    g.set_x_axis_steps(7)
    g.set_y_max(100)
    g.set_y_label_steps(10)
    g.set_x_axis_color('#818D9D', '#ccccff' )
    g.set_y_axis_color( '#818D9D', '#ddddff' )
    g.set_bg_color('#FFFFFF')
    render :text => g.render
  end
end
