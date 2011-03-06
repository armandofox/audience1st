module TemplateTagHelper

  def template_path(filename)
    compute_public_path(filename, 'templates', 'csv')
  end
  
end
