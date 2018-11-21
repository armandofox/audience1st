class EmailList
  require 'digest'              # for computing MD5 hashes of email addresses
  
  # this version works with the Gibbon gem for Mailchimp API v3.0

  attr_reader :errors, :disabled

  def initialize
    @apikey = Option.mailchimp_key
    @disabled = true
    Rails.logger.info("email_list: NOT initializing mailchimp") and return nil if (@apikey.blank? || @list.blank?)
    @disabled = false
    Rails.logger.info "email_list: Init Mailchimp"
  end

  private

  def mc
    Gibbon::Request.new(:api_key => @apikey, :symbolize_keys => true)
  end
  
  def default_list_id
    @default_list ||= mc.lists.retrieve.body['lists'][0]['id']
  end

  def segment_id_from_name(name)
    @mailchimp.static_segments(@listid).detect { |s| s['name'] == name }['id']
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
      mc.lists(default_list_id).members.create(:body => mailchimp_body_for(cust))
    rescue Gibbon::MailChimpError, StandardError => e
      @errors = e.message
      Rails.logger.info "email_list: #{@errors}"
    end
  end

  def update(cust, old_email)
    return nil if @disabled
    what = "updating #{cust.full_name} from #{old_email} to #{cust.email}"
    begin
      # 'upsert' modifies a user if exists, or adds if not. But can still fail if the
      #  updated (new) info duplicates an existing email address, which gives HTTP 400.
      digest = Digest::MD5.hexdigest(old_email.downcase)
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
    return nil if @disabled
    what = "unsubscribing #{cust.full_name} as #{email}"
    digest = Digest::MD5.hexdigest(cust.email.downcase)
    begin
      mc.lists(default_list_id).update(:body => {:status => 'unsubscribed'})
    rescue Gibbon::MailChimpError, StandardError => e
      @errors = e.message
      Rails.logger.warn "email_list: #{what}: #{@errors}"
    end
  end

  def create_sublist_with_customers(name, customers)
    create_sublist(name) && add_to_sublist(name, customers)
  end

  def create_sublist(name)
    return nil if @disabled
    begin
      @mailchimp.add_static_segment(@listid, name)
      true
    rescue Hominid::APIError => e
      @errors = "List segment '#{name}' could not be created: #{e.message}"
      Rails.logger.warn error
      nil
    end
  end

  def get_sublists
    # returns array of 2-element arrays, each of which is [name,count] for static segments
    return [] if @disabled
    begin
      segs = @mailchimp.static_segments(@listid).map { |seg| [seg['name'], seg['member_count']] }
      puts "Returning static segments: #{segs}"
      segs
    rescue Exception => e
      Rails.logger.info "Getting sublists: #{e.message}"
      []
    end
  end

  def add_to_sublist(sublist,customers=[])
    return nil if @disabled
    begin
      seg_id = segment_id_from_name(sublist)
      emails = customers.select { |c| c.valid_email_address? }.map { |c| c.email }
      if emails.empty?
        @errors = "None of the matching customers had valid email addresses."
        return 0
      end
      result = @mailchimp.static_segment_add_members(@listid, seg_id, emails)
      if !result['errors'].blank?
        @errors = "MailChimp was unable to add #{result['errors'].length} of the customers, usually because they aren't subscribed to the master list."
      end
      return result['success'].to_i
    rescue StandardError => e
      @errors = e.message
      Rails.logger.info "Adding #{customers.length} customers to sublist '#{sublist}': #{e.message}"
      return 0
    end
  end

end
