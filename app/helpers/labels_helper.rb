module LabelsHelper

  def checkbox_for_label(l, checked=false)
    check_box_tag("label[#{l.id}]", 1, checked) + 
      content_tag('label', l.name, :for => "label_#{l.id}")
  end

end
