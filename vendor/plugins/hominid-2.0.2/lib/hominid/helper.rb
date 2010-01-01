module Hominid
  module Helper
    
    # HELPER METHODS
    
    def account_details
      # Retrieve lots of account information including payments made, plan info,
      # some account stats, installed modules, contact info, and more. No private
      # information like Credit Card numbers is available.
      #
      # Parameters:
      # options (Hash) = 
      #
      # Returns:
      # An array of account details for this API key including:
      # username        (String)    = The Account username.
      # user_id         (String)    = The Account user unique id (for building some links).
      # is_trial        (Boolean)   = Whether the Account is in Trial mode.
      # timezone        (String)    = The timezone for the Account.
      # plan_type       (String)    = Plan Type - "monthly", "payasyougo", or "free".
      # plan_low        (Integer)   = Only for Monthly plans - the lower tier for list size.
      # plan_high       (Integer)   = Only for Monthly plans - the upper tier for list size.
      # plan_start_date (DateTime)  = Only for Monthly plans - the start date for a monthly plan.
      # emails_left     (Integer)   = Only for Free and Pay-as-you-go plans emails credits left for the account.
      # pending_monthly (Boolean)   = Whether the account is finishing Pay As You Go credits before switching to
      #                               a Monthly plan.
      # first_payment   (DateTime)  = Date of first payment.
      # last_payment    (DateTime)  = Date of most recent payment.
      # times_logged_in (Integer)   = Total number of times the account has been logged into via the web.
      # last_login      (DateTime)  = Date/time of last login via the web.
      # affiliate_link  (String)    = Monkey Rewards link for our Affiliate program.
      # contact         (Array)     = Contact details for the account, including: First & Last name, email, company
      #                               name, address, phone, and url.
      # addons          (Array)     = Addons installed in the account and the date they were installed.
      # orders          (Array)     = Order details for the account, include order_id, type, cost, date/time, and any
      #                               credits applied to the order.
      #
      hash_to_object(call("getAccountDetails"))
    end
    
     def inline_css(html, strip_css = false)
       # Send your HTML content to have the CSS inlined and optionally remove the original styles.
       #
       # Paramters:
       # html       (String)  = Your HTML content.
       # strip_css  (Boolean) = Whether you want the CSS <style> tags stripped from the returned document. Defaults to false.
       #
       # Returns:
       # Your HTML content with all CSS inlined, just like if we sent it. (String)
       #
      call("inlineCss", html, strip_css)
    end
    alias :convert_css_to_inline :inline_css
    
    def create_folder(name)
      # Create a new folder to file campaigns in.
      #
      # Parameters:
      # name (String) = A unique name for a folder.
      #
      # Returns:
      # The folder_id of the newly created folder. (Integer)
      call("createFolder", name)
    end
    
    def generate_text(type, content)
      # Have HTML content auto-converted to a text-only format. You can send: plain HTML, an array of Template content,
      # an existing Campaign Id, or an existing Template Id. Note that this will not save anything to or update any of
      # your lists, campaigns, or templates.
      #
      # Parameters:
      # type    (String) = Must be one of: "html", "template", "url", "cid", or "tid".
      # content (String) = The content to use. For "html" expects a single string value, "template" expects an array
      #                    like you send to campaignCreate, "url" expects a valid & public URL to pull from, "cid"
      #                    expects a valid Campaign Id, and "tid" expects a valid Template Id on your account.
      #
      # Returns:
      # The content passed in converted to text. (String)
      #
      call("generateText", type, content)
    end
    
    def ping(options = {})
      # "Ping" the MailChimp API - a simple method you can call that will return a constant value as long as everything
      # is good. Note than unlike most all of our methods, we don't throw an Exception if we are having issues. You will
      # simply receive a different string back that will explain our view on what is going on.
      #
      # Returns:
      # "Everything's Chimpy!"
      #
      call("ping")
    end
    
  end
end