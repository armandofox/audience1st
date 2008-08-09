module OptionsHelper

  def edit_field_for(v)
    case v.typ
    when :int
      text_field_tag "values[#{v.name}]", v.value, :size => 6, :maxlength => 6
    when :string
      text_field_tag "values[#{v.name}]", v.value, :size => 60
    when :text
      text_area_tag "values[#{v.name}]", v.value, :rows => 6, :cols => 60
    else
      text_field_tag "values[#{v.name}]", v.value, :size => 6, :maxlength => 6
    end
  end
end
