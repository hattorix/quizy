class QuestionBook < ActiveRecord::Base
  belongs_to :book, :dependent => :destroy
  belongs_to :question, :dependent => :destroy
end
