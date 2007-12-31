class Option < ActiveRecord::Base
  validates_uniqueness_of :name
  def validate
    errors.add(name.humanize, "must be an integer") if
      typ == :int and value =~ /[^0-9]/
    errors.add(name.humanize, "must be an email address") if
      typ == :email and !(value.valid_email_address?)
    errors.add(name.humanize, "must be a decimal number") if
      typ == :float and value !~ /[^0-9.]/
    return !errors.empty?
  end
  
end
