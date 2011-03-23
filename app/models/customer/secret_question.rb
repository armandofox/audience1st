class Customer < ActiveRecord::Base

  validates_numericality_of(:secret_question,
    :greater_than_or_equal_to => 0,
    :less_than => APP_CONFIG[:secret_questions].length)
  validates_length_of :secret_answer, :maximum => 40, :allow_nil => true
  validates_presence_of(:secret_answer,
    :if => Proc.new { |c| c.secret_question > 0 },
    :message => 'must be given if you specify a question')

  def check_secret_answer(str)
    str.blank? ? nil :
      self.secret_answer.gsub(/\s+/,' ').downcase == str.gsub(/\s+/,' ').downcase
  end

end
