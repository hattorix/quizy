class Book < ActiveRecord::Base
  has_many :question_books
  has_many :questions, :through => :question_books

  validates_presence_of :name,
                        :message => 'を入力してください。'
  validates_inclusion_of :is_public,
                         :in => 1..2,
                         :message => 'を選択してください。'
 class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "name" => "ブック名",
      "is_public" => "公開可否"
    }
    
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end
end
