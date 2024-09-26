class AccountCode < ActiveRecord::Base

  class NullAccountCode
    include Singleton
    def id ; 0 ; end
    def code ; '' ; end
    def name ;        '[No account code]' ; end
    def description ; '[No account code]' ; end
    def donation_prompt ; '' ; end
  end

  default_scope { order('code') }

  has_many :donations
  has_many :recurring_donations
  has_many :vouchertypes

  validates_length_of :name, :maximum => 255, :allow_nil => true
  validates_uniqueness_of :name, :allow_nil => true
  validates_uniqueness_of :code
  validate :name_or_code_given

  validates_length_of :donation_prompt, :maximum => 255, :allow_nil => true

  def name_or_code_given
    !name.blank? || !code.blank?
  end

  def self.default_account_code_id
    self.default_account_code.id
  end
  
  def self.default_account_code
    AccountCode.first
  end

  def <=>(other)
    if self.try(:code) && other.try(:code)
      self.code <=> other.code
    else
      self.try(:name).to_s <=> other.try(:name).to_s
    end
  end

  class CannotDelete < RuntimeError ;  end
  
  # convenience accessors

  def name_or_code ;    name.blank? ? code : name        ; end
  def name_with_code ;  sprintf("%-6.6s %s", code, name)  ; end
  
  # cannot delete the last account code or the one associated as any
  # of the defaults

  before_destroy :can_be_deleted?

  def can_be_deleted?
    errors.add(:base,'at least one account code must exist') and throw(:abort) if AccountCode.count < 2
    Option.columns_hash.keys.select { |name| name =~ /account_code/ }.each do |option|
      errors.add(:base, "it's the #{option.humanize.downcase}") and throw(:abort) if
        code == Option.send(option)
    end
  end

end
