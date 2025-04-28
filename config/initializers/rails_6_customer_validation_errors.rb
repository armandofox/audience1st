module Rails6CustomerValidationErrors

  # sadly, the only way to customize the behavior of #full_message in Rails 6 is
  # to globally override/monkeypatch ActiveModel::Error but fall back to the built-in
  # behavior for anything other than specific model(s).
  # IMO this is a big drawback that makes me wonder about the ActiveModel::Error refactoring.

  def full_message
    return super if (! base.kind_of?(Customer)) || attribute == :base
    customer_name =
      if !base.full_name.blank? then base.full_name
      elsif base.new_record? then 'New unnamed customer'
      else "Customer ID #{base.id}"
      end
    "#{customer_name}: #{super}"      
  end
    
  ActiveModel::Error.prepend(Rails6CustomerValidationErrors)
  
end
