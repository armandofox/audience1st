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

  def self.value(name)
    opt = Option.find_by_name(name).get_value
  end

  # read all configuration options from database
  def self.read_all_options
    Hash[*(Option.find(:all).map { |o| [o.name.to_sym,o.get_value] }.flatten)]
  end
  
  def get_value
    case self.typ
    when :int
      self.value.to_i
    when :float
      self.value.to_f
    else                        # string or text field
      self.value
    end
  end
    
end
