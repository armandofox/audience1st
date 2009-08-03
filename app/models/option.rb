class Option < ActiveRecord::Base
  validates_uniqueness_of :name
  def validate
    value.strip unless value.blank?
    case typ
      when :int
      errors.add(name.humanize, "must be an integer") unless
        value.kind_of?(Fixnum) || value.to_s =~ /^[0-9]+$/
      when :email
      errors.add(name.humanize, "must be an email address") unless
        value.valid_email_address?
      when :float
      errors.add(name.humanize, "must be a decimal number") unless
        value.kind_of?(Float) || value.to_s =~ /^[0-9.]+$/
    end
    return !errors.empty?
  end

  def self.value(name)
    (opt = Option.find_by_name(name)) ?
    opt.get_value :
      nil
  end

  def self.values_hash(*ary)
    Hash[*(ary.map { |p| [p, Option.value(p)] }.flatten)]
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
