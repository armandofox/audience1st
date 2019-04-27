module I18nHelper
  # Lets you write step def such as:
  # Then I should see the message for "customers.confirm_delete"
  Then /I should see the message for "(.*)"/ do |i18n_key|
    message = I18n.translate!(i18n_key).gsub()
    steps %Q{Then I should see "#{message}"}
  end
end
World(I18nHelper)
