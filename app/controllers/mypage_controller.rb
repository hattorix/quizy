class MypageController < ApplicationController
  before_filter :login_required
  def index
    # カテゴリ一覧
    @categories = Category.find(:all, :order => 'id')

    # マイブック一覧
    mybooks = MyBook.find(:all,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    mybook_ids = Array.new
    mybooks.each do |b|
      mybook_ids << b.id
    end
    @mybooks = MyBook.paginate_by_id mybook_ids, :page => params[:book_page], :per_page => 7,:order => "created_at desc"

    # マイテスト一覧
    myexams = MyExam.find(:all,
                       :conditions => ['user_id = ?', current_user.id],
                       :order => "created_at desc")
    myexam_ids = Array.new
    myexams.each do |e|
      myexam_ids << e.id
    end
    @myexams = MyExam.paginate_by_id myexam_ids, :page => params[:exam_page], :per_page => 8,:order => "created_at desc"

    # 最近登録した問題
    @questions = Question.find(:all, :limit => 10, :order => "created_at desc",
                               :conditions => ['user_id = ?', current_user.id])
    # 最近解答した問題
    @histories = Array.new
    all_histories = History.find(:all, :order => "created_at desc",
                               :conditions => ['user_id = ?', current_user.id])
    all_histories.each do |history|
      if Question.find(:first,:conditions => ["id = ?",history.question_id])
        @histories << history
      end
      if @histories.size == 10
        break
      end
    end
  end
  
  def message
    flash[:notice] = params[:message]
    redirect_to :action => "index"
  end
  
  def result
    @graph_a = open_flash_chart_object(850,400, '/mypage/bar_chart_answer', true, '/')
    @graph_c = open_flash_chart_object(850,400, '/mypage/bar_chart_create', true, '/')
  end

  def bar_chart_answer
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
  
  def bar_chart_create
    bar1 = Bar.new(50, '#00CC00')
    bar1.key('作成数', 10)

    days = Array.new

    30.times do |t|
      y = t.day.ago.strftime("%y")
      m = t.day.ago.strftime("%m")
      d = t.day.ago.strftime("%d")

      first_time = Time.local(y, m, d, 00, 00, 00)
      last_time = Time.local(y, m, d, 23, 59, 59)


      bar1.data << Question.count(:conditions => ["created_at > ? and created_at < ? and user_id = ?",
                                                  first_time,
                                                  last_time,
                                                  current_user.id])
      days << last_time.strftime("%m/%d")
    end

    g = Graph.new
    first = 29.day.ago.strftime("%m/%d")
    last = Time.now.strftime("%m/%d")
    g.title("#{first}～#{last}に作成した問題数", "{font-size: 26px;}")

    g.data_sets << bar1

    g.set_x_labels(days)
    g.set_x_label_style(10, '#000000', 1, 1)
    g.set_x_axis_steps(7)
    g.set_y_max(20)
    g.set_y_label_steps(10)
    g.set_x_axis_color('#818D9D', '#ccccff' )
    g.set_y_axis_color( '#818D9D', '#ddddff' )
    g.set_bg_color('#FFFFFF')
    render :text => g.render
  end
end
