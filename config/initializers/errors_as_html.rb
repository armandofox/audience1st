# rails3 this will become ActiveModel::Base
class ActiveRecord::Base
  def errors_as_html(sep = '<br/>')
    errors.full_messages.join(sep)
  end
end
