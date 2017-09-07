module ImportsHelper

  def partial_for(str)
    str.tableize.singularize << "_help"
  end
  def partial_names_for(hsh)
    hsh.reduce({}) { |h, (key,val)| h.merge(val => partial_for(val)) }
  end
end
