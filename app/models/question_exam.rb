class QuestionExam < ActiveRecord::Base
  belongs_to :exam, :dependent => :destroy
  belongs_to :question, :dependent => :destroy
end
