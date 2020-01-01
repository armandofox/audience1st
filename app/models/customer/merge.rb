class Customer < ActiveRecord::Base
  
  # merge myself with another customer.  'params' array indicates which
  # record (self or other) to retain each field value from.  For
  # password and salt, the ones corresponding to most recent
  # last_login are retained.  If those are equal, keep whichever was
  # most recently updated (updated_at).  IF those are also equal, keep
  # the first one.

  # merge with Anonymous customer, keeping all transactions

  def forget!
    return nil unless deletable?
    begin
      transaction do
        Customer.update_foreign_keys_from_to(self.id, Customer.anonymous_customer.id)
        self.destroy
      end
    rescue StandardError => e
      self.errors.add :base,"Cannot forget customer #{id} (#{full_name}): #{e.message}"
    end
    return self.errors.empty?
  end

  def merge_with_params!(c1,params)
    return nil unless self.mergeable_with?(c1)
    Customer.replaceable_attributes.each do |attr|
      if (params[attr.to_sym].to_i > 0)
        self.send("#{attr}=", c1.send(attr))
      end
    end
    finish_merge(c1)
    return Customer.save_and_update_foreign_keys!(self, c1)
  end
  
  def merge_automatically!(c1)
    return nil unless self.mergeable_with?(c1)
    replace = c1.fresher_than?(self) && !c1.created_by_admin?
    Customer.replaceable_attributes.each do |attr|
      self.send("#{attr}=", c1.send(attr)) if replace || self.send(attr).blank?
    end
    finish_merge(c1)
    return Customer.save_and_update_foreign_keys!(self, c1)
  end
        
  def mergeable_with?(other)
    if other.special_customer? || self.is_admin || other.is_admin
      self.errors.add :base,"Special customers and super admins cannot be merged"
    elsif (self.special_customer? && self != Customer.anonymous_customer)
      self.errors.add :base,"Merges disallowed into all special customers except Anonymous customer"
    end
    self.errors.empty?
  end
  

  def fresher_than?(other)
    begin
      (self.updated_at > other.updated_at) ||
        (self.updated_at == other.updated_at &&
        self.last_login > other.last_login)
    rescue
      nil
    end
  end

  private

  def finish_merge(c1)
    %w(comments tags role blacklist e_blacklist created_by_admin).each do |attr|
      newval = merge_attribute(c1, attr)
      self.send("#{attr}=", newval)
    end
  end

  def merge_attribute(other, attr)
    v1 = self.send(attr)
    v2 = other.send(attr)
    newval =
      case attr.to_sym
      when :comments then [v1,v2].reject { |c| c.blank? }.join('; ')
      when :tags then (v1.to_s.downcase.split(/\s+/)+v2.to_s.downcase.split(/\s+/)).uniq.join(' ')
      when :role then [v1.to_i, v2.to_i].max  
      when :blacklist, :e_blacklist  then v1 || v2
      when :created_by_admin, :inactive then v1 && v2
      else raise "No automatic merge procedure for #{attr.to_s.humanize}"
      end
  end

  # Note: This method should only be called inside a transaction block!
  def self.update_foreign_keys_from_to(old,new)
    msg = []
    [Order, Item, Txn].each do |t|
      howmany = 0
      t.foreign_keys_to_customer.each do |field|
        howmany += t.where("#{field} = ?", old).update_all(field => new)
      end
      msg << "#{howmany} #{t}s"
    end
    msg
  end

  def self.save_and_update_foreign_keys!(c0,c1)
    new = c0.id
    old = c1.id
    ok = nil
    msg = []
    begin
      transaction do
        msg = Customer.update_foreign_keys_from_to(old, new)
        # Add/merge labels from old record to new
        label_count = (c1.labels - c0.labels).size
        c0.labels += c1.labels
        msg << "#{label_count} labels"
        # Definitively propagate provenance (either ticket_sales_import_id, or nil)
        # from the older record.
        if c0.created_at > c1.created_at # c1 is older,but c0 will be result of merge
          c0.ticket_sales_import_id = c1.ticket_sales_import_id
        end
        # Crypted_password and salt have to be updated separately,
        # since crypted_password is automatically set by the before-save
        # action to be encrypted with salt.
        if c1.fresher_than?(c0)
          pass = c1.crypted_password
          salt = c1.salt
        else
          pass = nil
        end
        c1.destroy
        c0.save!
        if pass
          Customer.connection.execute("UPDATE customers SET crypted_password='#{pass}',salt='#{salt}' WHERE id=#{c0.id}")
        end
        ok = "Transferred " + msg.join(", ") + " to customer id #{new}"
      end
    rescue StandardError => e
      c0.errors.add :base,"Customers NOT merged: #{e.message}"
    end
    return ok
  end

end
