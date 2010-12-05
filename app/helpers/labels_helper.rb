module LabelsHelper

  def checkbox_for_label(l, checked=false)
    check_box_tag("label[#{l.id}]", 1, checked) + 
      content_tag('label', l.name, :for => "label_#{l.id}",
      :class => 'no_float')  
  end

  def link_to_label_list(l)
  end
    
end
