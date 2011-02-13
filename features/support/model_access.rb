module ModelAccess

  def get_model_instance(entity_type, attribute, value)
    (entity_type.underscore.capitalize.constantize.send("find_by_#{attribute}", value)) ||
      raise("#{entity_type.capitalize} with #{attribute} #{value} not found")
  end

end
