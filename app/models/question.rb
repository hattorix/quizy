class Question < ActiveRecord::Base
  acts_as_taggable

  belongs_to :category
  has_many :question_books
  has_many :histories
  has_many :categories, :through => :question_books
  has_many :selections, :dependent => :destroy
  has_one :answer,      :dependent => :destroy
  has_one :description, :dependent => :destroy
  
  validates_presence_of :question_text,
                        :message => 'を入力してください。'
  
  def validate
    # 解答が入力の場合
    if question_type == 4
      if answer.answer_text.size == 0
        errors.add("解答を入力してください。")
      end
    # 解答が選択の場合
    elsif question_type ==1 ||question_type ==2
      if selections.reject{ |s| s.selection_text == "" }.size < 2
        errors.add("選択肢を２つ以上入力してください。")
      end
      # 正解が選択されているか調べる
      is_collects = Array.new
      selections.each do |selection|
          is_collects << selection.is_collect
      end
      if !is_collects.include?(1)
        errors.add("正解を選択してください。")
      end
      selections.each do |s|
        if s.selection_text == "" and s.is_collect == 1
          errors.add("正解の選択肢を入力してください。")
          break
        end
      end
    end
  end
  
  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "question_text" => "問題文",
    }
    
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end
end
