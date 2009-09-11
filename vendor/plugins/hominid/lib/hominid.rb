require 'xmlrpc/client'

class HominidError < RuntimeError
  def initialize(message)
    super(message)
  end
end

class HominidCommunicationError < HominidError
  def initialize(message)
    super(message)
  end
end

class Hominid
  
  # MailChimp API Documentation: http://www.mailchimp.com/api/1.2/
  MAILCHIMP_API = "http://api.mailchimp.com/1.2/"

  def initialize(config = nil)
    load_monkey_brains(config)
    @chimpApi ||= XMLRPC::Client.new2(MAILCHIMP_API)
  end

  def load_monkey_brains(config)
    config = YAML.load(File.open("#{RAILS_ROOT}/config/hominid.yml"))[RAILS_ENV].symbolize_keys unless config
    @chimpUsername  = config[:username].to_s
    @chimpPassword  = config[:password].to_s
    @api_key        = config[:api_key]
    @send_goodbye   = config[:send_goodbye]
    @send_notify    = config[:send_notify]
    @double_opt     = config[:double_opt]
  end
  
  ## Security related methods
  
  def add_api_key
    begin
      @chimpApi ||= XMLRPC::Client.new2(MAILCHIMP_API)
      @chimpApi.call("apikeyAdd", @chimpUsername, @chimpPassword, @api_key)
    rescue
      false
    end
  end
  
  def expire_api_key
    begin
      @chimpApi ||= XMLRPC::Client.new2(MAILCHIMP_API)
      @chimpApi.call("apikeyExpire", @chimpUsername, @chimpPassword, @api_key)
    rescue
      false
    end
  end
  
  def api_keys(include_expired = false)
    begin
      @chimpApi ||= XMLRPC::Client.new2(MAILCHIMP_API)
      @api_keys = @chimpApi.call("apikeys", @chimpUsername, @chimpPassword, include_expired)
    rescue
      return nil
    end
  end
  
  ## Campaign related methods
  
  def campaign_content(campaign_id)
    # Get the content of a campaign
    @content = call("campaignContent", campaign_id)
  end
  
  def campaigns(filters = {}, start = 0, limit = 50)
    # Get the campaigns for this account
    # API Version 1.2 requires that filters be sent as a hash
    # Available options for the filters hash are:
    #
    #   :campaign_id    = (string)  The ID of the campaign you wish to return. 
    #   :list_id        = (string)  Show only campaigns with this list_id. 
    #   :folder_id      = (integer) Show only campaigns from this folder.
    #   :from_name      = (string)  Show only campaigns with this from_name.
    #   :from_email     = (string)  Show only campaigns with this from_email.
    #   :title          = (string)  Show only campaigns with this title.
    #   :subject        = (string)  Show only campaigns with this subject.
    #   :sedtime_start  = (string)  Show campaigns sent after YYYY-MM-DD HH:mm:ss.
    #   :sendtime_end   = (string)  Show campaigns sent before YYYY-MM-DD HH:mm:ss.
    #   :subject        = (boolean) Filter by exact values, or search within content for filter values.
    @campaigns = call("campaigns", filters, start, limit)
  end

  # Attach Ecommerce Order Information to a Campaign.
  # The order hash should be structured as follows: 
  #
  #   :id             = (string)  the order id 
  #   :campaign_id    = (string)  the campaign id to track the order (mc_cid query string). 
  #   :email_id       = (string)  email id of the subscriber (mc_eid query string)
  #   :total          = (double)  Show only campaigns with this from_name.
  #   :shipping       = (string)  *optional - the total paid for shipping fees.
  #   :tax            = (string)  *optional - the total tax paid.
  #   :store_id       = (string)  a unique id for the store sending the order in
  #   :store_name     = (string)  *optional - A readable name for the store, typicaly the hostname.
  #   :plugin_id      = (string)  the MailChimp-assigned Plugin Id. Using 1214 for the moment. 
  #   :items          = (array)   the individual line items for an order, using the following keys:
  #     
  #     :line_num      = (integer) *optional - line number of the item on the order
  #     :product_id    = (integer) internal product id
  #     :product_name  = (string)  the name for the product_id associated with the item
  #     :category_id   = (integer) internal id for the (main) category associated with product
  #     :category_name = (string)  the category name for the category id
  #     :qty           = (double)  the quantity of items ordered
  #     :cost          = (double)  the cost of a single item (i.e., not the extended cost of the line)
  def campaign_ecomm_add_order(order)
    @campaign = call("campaignEcommAddOrder", order)
  end

  def create_campaign(type = 'regular', options = {}, content = {}, segment_options = {}, type_opts = {})
    # Create a new campaign
    @campaign = call("campaignCreate", type, options, content, segment_options, type_opts)
  end
  
  def delete_campaign(campaign_id)
    # Delete a campaign
    @campaign = call("campaignDelete", campaign_id)
  end
  
  def replicate_campaign(campaign_id)
    # Replicate a campaign (returns ID of new campaign)
    @campaign = call("campaignReplicate", campaign_id)
  end
  
  def schedule_campaign(campaign_id, time = "#{1.day.from_now}")
    # Schedule a campaign
    ## TODO: Add support for A/B Split scheduling
    call("campaignSchedule", campaign_id, time)
  end
  
  def send_now(campaign_id)
    # Send a campaign
    call("campaignSendNow", campaign_id)
  end
  
  def send_test(campaign_id, emails = {})
    # Send a test of a campaign
    call("campaignSendTest", campaign_id, emails)
  end
  
  def templates
    # Get the templates
    @templates = call("campaignTemplates", @api_key)
  end
  
  def update_campaign(campaign_id, name, value)
    # Update a campaign
    call("campaignUpdate", campaign_id, name, value)
  end
  
  def unschedule_campaign(campaign_id)
    # Unschedule a campaign
    call("campaignUnschedule", campaign_id)
  end
  
  ## Helper methods
  
  def html_to_text(content)
    # Convert HTML content to text
    @html_to_text = call("generateText", 'html', content)
  end
  
  def convert_css_to_inline(html, strip_css = false)
    # Convert CSS styles to inline styles and (optionally) remove original styles
    @html_to_text = call("inlineCss", html, strip_css)
  end
  
  ## List related methods
  
  def lists
    # Get all of the lists for this mailchimp account
    @lists = call("lists", @api_key)
  end
  
  def create_group(list_id, group)
    # Add an interest group to a list
    call("listInterestGroupAdd", list_id, group)
  end
  
  def create_tag(list_id, tag, name, required = false)
    # Add a merge tag to a list
    call("listMergeVarAdd", list_id, tag, name, required)
  end
  
  def delete_group(list_id, group)
    # Delete an interest group for a list
    call("listInterestGroupDel", list_id, group)
  end
  
  def delete_tag(list_id, tag)
    # Delete a merge tag and all its members
    call("listMergeVarDel", list_id, tag)
  end
  
  def groups(list_id)
    # Get the interest groups for a list
    @groups = call("listInterestGroups", list_id)
  end
  
  def member(list_id, email)
    # Get a member of a list
    @member = call("listMemberInfo", list_id, email)
  end
  
  def members(list_id, status = "subscribed", since = "2000-01-01 00:00:00", start = 0, limit = 100)
    # Get members of a list based on status
    # Select members based on one of the following statuses:
    #   'subscribed'
    #   'unsubscribed'
    #   'cleaned'
    #   'updated'
    #
    # Select members that have updated their status or profile by providing
    # a "since" date in the format of YYYY-MM-DD HH:MM:SS
    # 
    @members = call("listMembers", list_id, status, since, start, limit)
  end
  
  def merge_tags(list_id)
    # Get the merge tags for a list
    @merge_tags = call("listMergeVars", list_id)
  end
  
  def subscribe(list_id, email, user_info = {}, email_type = "html", update_existing = true, replace_interests = true, double_opt_in = nil)
    # Subscribe a member
    call("listSubscribe", list_id, email, user_info, email_type, double_opt_in || @double_opt, update_existing, replace_interests)
  end
  
  def subscribe_many(list_id, subscribers)
    # Subscribe a batch of members
    # subscribers = {:EMAIL => 'example@email.com', :EMAIL_TYPE => 'html'} 
    call("listBatchSubscribe", list_id, subscribers, @double_opt, true)
  end
  
  def unsubscribe(list_id, current_email)
    # Unsubscribe a list member
    call("listUnsubscribe", list_id, current_email, true, @send_goodbye, @send_notify)
  end
  
  def unsubscribe_many(list_id, emails)
    # Unsubscribe an array of email addresses
    # emails = ['first@email.com', 'second@email.com'] 
    call("listBatchUnsubscribe", list_id, emails, true, @send_goodbye, @send_notify)
  end
  
  def update_member(list_id, current_email, user_info = {}, email_type = "")
    # Update a member of this list
    call("listUpdateMember", list_id, current_email, user_info, email_type, true)
  end
  
  protected
  def call(method, *args)
    @chimpApi.call(method, @api_key, *args)
  rescue XMLRPC::FaultException => error
    raise HominidError.new(error.message)
  rescue Exception => error
    raise HominidCommunicationError.new(error.message)
  end
end
