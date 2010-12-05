module LabelHelpers

  def find_or_create_label(name)
    Label.find_by_name(name) || Label.create!(:name => name)
  end
    
end

World(LabelHelpers)
