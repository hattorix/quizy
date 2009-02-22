class Exam < ActiveRecord::Base
  has_many :question_exams
  has_many :questions, :through => :question_exams
  validates_presence_of :name,
                        :message => 'を入力してください'
  validates_numericality_of :time_limit,
                            :only_integer => true,
                            :message => 'を整数で入力してください。'
  validates_inclusion_of :border_line,
                         :in => 1..100,
                         :message => 'を1から100で入力してください。'
  validates_inclusion_of :is_public,
                         :in => 1..2,
                         :message => 'を1または2で入力してください。'

 class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "name" => "テスト名",
      "time_limit" => "制限時間",
      "border_line" => "合格ライン",
      "is_public" => "公開可否"
    }
    
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end
end