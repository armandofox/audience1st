module CustomReportsHelper

  def clause_check_box(c,checked)
    check_box_tag "use[#{c.name}]", 1, checked
  end
    

  def clause_select(c)
    if (c.choices.nil? || c.choices.empty?)
      ""
    else
      select_tag("#{c.name}_select",
                 options_for_select(c.choices.map { |t| t[:label] }))
    end
  end

  def clause_params(c)
    case c.param_type
    when :datetime
    when :date
      select_date Date.today, :prefix => c.name.to_s
    when :date_range
      s = select_date_with_shortcuts(:from => Date.today, :to => Date.today, :start_year => Date.today.year - 2, :prefix => c.name.to_s)
      "#{s[0]}<br/>From #{s[1]}<br/>to #{s[2]}"
    when :text
      text_field_tag c.name, '', :size => 20
    else
      ""
    end
  end
  
end
