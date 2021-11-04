class OptionsController < ApplicationController

  before_filter :is_admin_filter
  
  def index
    @o = Option.first
  end

  def update
    @o = Option.first
    option_params = params.require('option').permit!
    params.permit('html_email_template')
    # for sales cutoff, use dropdown menu 'minutes before/after' to modify actual value
    option_params['advance_sales_cutoff'] =
      option_params['advance_sales_cutoff'].to_i * params['before_or_after'].to_i
    # if there is a file upload for HTML template, get it
    option_params['html_email_template'] = params['html_email_template'].read unless params['html_email_template'].blank?
    if (@o.update_attributes(option_params))
      redirect_to options_path, :notice => "Update successful."
    else
      flash.now[:alert] = @o.errors.as_html
      render :action => :index
    end
  end

  def email_test
    @email = params[:addr]
    begin
      Mailer.send(:email_test, @email).deliver_now
      render :text => "A test email was sent to #{@email}."
    rescue Net::SMTPError,RuntimeError => e
      render :text => "Test email could not be sent.  The error was: #{e.message}"
    end
  end

  def download_email_template
    send_data(Option.html_email_template, :type => 'text/html', :filename => 'email_template.html')
  end
end
