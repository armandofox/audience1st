# if RAILS_ENV == 'production'
#   # bug: this if clause should just be moved to environments/production.rb,
#   # but currently you're allowed only a single after_initialize hook.
#   ExceptionNotifier.sender_address =
#     %("EXCEPTION NOTIFIER" <bugs@audience1st.com>)
#   ExceptionNotifier.exception_recipients =
#     %w(armandofox@gmail.com)
# end
