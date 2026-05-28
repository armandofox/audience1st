# config/initializers/core_extensions.rb

# allow ACtiveRecord to hash-serialize models that include non-primitive classes.
# see https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
# it's safe here because we're constructing the input ourselves
Rails.application.config.active_record.use_yaml_unsafe_load = true

Rails.application.config.to_prepare do
  # Ruby core classes
  Time.include CoreExtensions::Time::ShowtimeDateFormats
  Time.include CoreExtensions::Time::RoundedTo
  Time.include CoreExtensions::Time::Season
  Time.include CoreExtensions::Time::ToParam
  
  Date.include CoreExtensions::Date::Season
  
  String.include CoreExtensions::String::Name
  String.include CoreExtensions::String::Colorize

  # Rails internal classes
  ActiveModel::Errors.include ActiveModel::Errors::HtmlFormatter

end
