module OptionsHelper

  def edit_field_for(v)
    name = "values[#{v.name}]"
    case v.typ
    when :int
      text_field_tag name, v.value, :size => 6, :maxlength => 6
    when :string, :email
      text_field_tag name, v.value, :size => 60
    when :text
      text_area_tag name, v.value, :rows => 6, :cols => 60
    else
      text_field_tag name, v.value, :size => 6, :maxlength => 6
    end
  end
end
