class Report < ActiveRecord::Base
  validates_presence_of :description,
                        :message => 'を記入してください。'

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "description" => "内容",
    }
    
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end
end
