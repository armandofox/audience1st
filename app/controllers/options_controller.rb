class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def index
    @o = Option.first
  end

  def update
    @o = Option.first
    if (@o.update_attributes(params['option']))
      flash[:notice] = "Update successful."
    else
      flash[:alert] = @o.errors.as_html
    end
    redirect_to options_path
  end

  def email_test
    @email = params[:email]
    begin
      Mailer.send(:email_test, @email).deliver_now
      flash[:notice] = "A test email was sent to #{@email}."
    rescue Net::SMTPError,RuntimeError => e
      flash[:alert] = "Test email could not be sent.  The error was: #{e.message}"
    end
    redirect_to options_path
  end

end
