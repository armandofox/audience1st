class EmailList
  require 'digest'              # for computing MD5 hashes of email addresses
  
  # this version works with the Gibbon gem for Mailchimp API v3.0

  attr_reader :errors, :disabled

  def initialize(key = nil)
    @apikey = key || (Option.mailchimp_key rescue nil)
    @disabled = !! @apikey.blank?
    @errors = nil
  end

  private

  def mc
    Gibbon::Request.new(:api_key => @apikey, :symbolize_keys => true)
  end
  
  def default_list_id
    @default_list ||= mc.lists.retrieve.body[:lists][0][:id]
  end

  def segments
    @segments ||=
      mc.lists(default_list_id).
      segments.retrieve.
      body[:segments].select { |seg| seg[:type] == 'static' }
  end

  def segment_id_from_name(name)
    (segments.detect { |s| s[:name] == name })[:id]
  end

  def customer_id_from(email)
    Digest::MD5.hexdigest(email.downcase)
  end
  
  def mailchimp_body_for(cust)
    {
      :email_address => cust.email,
      :status => (cust.e_blacklist? ? 'unsubscribed' : 'subscribed'),
      :merge_fields => {'FNAME' => cust.first_name, 'LNAME' => cust.last_name}
    }
  end
  
  public

  def subscribe(cust, email=cust.email)
    return true if disabled
    begin
      digest = customer_id_from(email)
      mc.lists(default_list_id).members(digest).upsert(:body => mailchimp_body_for(cust))
    rescue Gibbon::MailChimpError, StandardError => e
      @errors = e.message
      Rails.logger.info "email_list: #{@errors}"
    end
  end

  def update(cust, old_email)
    return nil if disabled
    what = "updating #{cust.full_name} from #{old_email} to #{cust.email}"
    begin
      # 'upsert' modifies a user if exists, or adds if not. But can still fail if the
      #  updated (new) info duplicates an existing email address, which gives HTTP 400.
      digest = customer_id_from(old_email)
      member = mc.lists(default_list_id).members(digest).upsert(:body => mailchimp_body_for(cust))
    rescue Gibbon::MailChimpError => e
      # check for and rescue 400, meaning email already exists.
      # TBD how to handle that case, since failure of this op must not block regular operation?
      @errors = e.message
      Rails.logger.warn "email_list: MailChimp error #{what}: #{@errors}"
    rescue StandardError => e
      @errors = e.message
      Rails.logger.warn "email_list: Unexpected error #{what}: #{@errors}"
    end
  end

  def unsubscribe(cust, email=cust.email)
    return nil if disabled
    what = "unsubscribing #{cust.full_name} as #{email}"
    digest = customer_id_from(cust.email)
    begin
      mc.lists(default_list_id).members(digest).update(:body => {:status => 'unsubscribed'})
    rescue Gibbon::MailChimpError => e
      if e.status_code == 404  # member not found: silently ignore
        true
      else
        @errors = e.message
        Rails.logger.warn "email_list: #{what}: #{@errors}"
        nil
      end
    rescue StandardError => e
      @errors = e.message
      Rails.logger.warn "email_list: #{what}: #{@errors}"
      nil
    end
  end

  def create_sublist_with_customers(name, customers)
    create_sublist(name) && add_to_sublist(name, customers)
  end

  def create_sublist(name)
    return nil if disabled
    begin
      mc.lists(default_list_id).segments.create(:body => {:name => name, :static_segment => []})
    rescue Gibbon::MailChimpError, StandardError => e
      @errors = "List segment '#{name}' could not be created: #{e.message}"
      Rails.logger.warn @errors
      nil
    end
  end

  def get_sublists
    # returns names of sublists
    return [] if disabled
    begin
      segments.map { |s| s[:name] }
    rescue Gibbon::MailChimpError => e
      Rails.logger.info "Getting sublists: #{e.message}"
      []
    end
  end

  def add_to_sublist(sublist,customers=[])
    return nil if disabled
    segs = segments
    begin
      seg_id = segment_id_from_name(sublist)
      emails = customers.select { |c| c.valid_email_address? }.map { |c| c.email }
      response = mc.lists(default_list_id).segments(seg_id).
        create(:body => {:members_to_add => emails})
      num_added = response.body[:total_added].to_i
      return num_added
    rescue Gibbon::MailChimpError, StandardError => e
      @errors = e.message
      Rails.logger.info "Adding #{customers.size} customers to sublist '#{sublist}': #{e.message}"
      return 0
    end
  end

end
