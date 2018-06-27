class Customer < ActiveRecord::Base

  attr_accessible :secret_question, :secret_answer
  
  validates_numericality_of(:secret_question,
    :greater_than_or_equal_to => 0,
    :less_than => t('app_config.secret_questions').length)
  validates_length_of :secret_answer, :maximum => 40, :allow_nil => true
  validates_presence_of(:secret_answer,
    :if => Proc.new { |c| c.secret_question > 0 },
    :message => 'must be given if you specify a question')
  validates_length_of(:secret_answer,
    :if => Proc.new { |c| c.secret_question == 0 },
    :is => 0, :allow_nil => true,
    :message => 'cannot be given unless you specify a question')

  def setup_secret_question_message
    'You can now setup a secret question to verify your identity in case you forget your password.  Click Change Password above to setup your secret question.'
  end

  def has_secret_question? ; !self.secret_question.zero? ; end
  
  def check_secret_answer(str)
    (str.blank? || !self.has_secret_question?) ? nil :
      self.secret_answer.gsub(/\s+/,' ').downcase == str.gsub(/\s+/,' ').downcase
  end

  def self.authenticate_from_secret_question(email, question, answer)
    # we don't actually check the question, just the answer...
    if email.blank? || answer.blank?
      u = Customer.new
      u.errors.add(:login_failed, 'Please provide your email and the answer to your chosen secret question.')
    elsif (u = Customer.where('email LIKE ?', email.downcase).first).nil?
      u = Customer.new
      u.errors.add(:login_failed,
        'Can\'t find that email address.  Maybe you registered with a different one?')
    elsif !u.has_secret_question?
      u.errors.add(:no_secret_question, "Sorry, but '#{email}' never set up a secret question.")
    elsif !(u.check_secret_answer(answer))
      u.errors.add(:incorrect_secret_question_answer, "Sorry, that isn't the answer you provided when you selected your secret question.")
    end
    u
  end
  
end
