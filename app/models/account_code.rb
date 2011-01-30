class AccountCode < ActiveRecord::Base
  has_many :donations
  has_many :vouchertypes

  validates_length_of :name, :maximum => 30, :allow_nil => true
  validates_uniqueness_of :name, :allow_nil => true
  validate :name_or_code_given

  def name_or_code_given
    !name.blank? || !code.blank?
  end
  
  def self.default_account_code_id
    self.default_account_code.id
  end
  
  def self.default_account_code
    AccountCode.find(:first) ||
      AccountCode.create!(:name => "General Fund",
      :code => '0000',
      :description => "General Fund")
  end

  # convenience accessors

  def name_or_code ;    name.blank? ? code : name        ; end
  def name_with_code ;  sprintf("%-6.6s #{name}", code)  ; end
  
end
