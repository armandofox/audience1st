class Customer < ActiveRecord::Base

  SEARCHABLE_COLUMNS = %w(street city zip day_phone eve_phone comments company email)

  # Tricky self-join for similarity: last names must match, emails must not differ,
  #  and at least one of first name or street must match.
  def self.find_suspected_duplicates
    last_name_matches = '(lower(customers.last_name)=lower(c2.last_name))'
    first_name_or_initial_matches_or_is_blank =
      "( (lower(customers.first_name) LIKE lower(c2.first_name))
         OR (SUBSTR(lower(customers.first_name),1,1)=lower(c2.first_name))
         OR (SUBSTR(lower(c2.first_name),1,1)=lower(customers.first_name))
       )"
    street_matches_or_is_blank =
      "( (lower(customers.street) LIKE lower(c2.street))
          OR (customers.street='' OR customers.street IS NULL)
          OR (c2.street='' OR c2.street IS NULL)
       )"

    sql = %Q{
      SELECT DISTINCT customers.*
      FROM customers JOIN customers c2 ON #{last_name_matches}
      WHERE customers.id != c2.id
        AND customers.role >= 0 AND c2.role >= 0
        AND #{first_name_or_initial_matches_or_is_blank}
        AND #{street_matches_or_is_blank}
      ORDER BY customers.last_name,customers.first_name
    }
    possible_dups = Customer.find_by_sql(sql)
  end
  
  # account for case where email matches but not last name

  def self.email_matches_diff_last_name?(p)
    email, last_name = p.email, p.last_name
    if !email.blank? && !last_name.blank?
        recipient = Customer.where('email LIKE ?', email.strip).first
        if !recipient.nil?
            recipient_last_name = recipient.last_name
            if last_name != recipient_last_name
                return true
            end
            return false
        end
        return false
    end
    return false
  end
 
  # given some customer info, find this customer in the database with
  # high confidence;  if not found or ambiguous, return nil

  def self.find_unique(p)
    return (
      match_email_and_last_name(p.email, p.last_name) ||
      match_first_last_and_address(p.first_name, p.last_name, p.street) ||
      (p.street.blank? ? match_uniquely_on_names_only(p.first_name, p.last_name) : nil)
      )
  end

  # support for find_unique

  def self.match_email_and_last_name(email,last_name)
    !email.blank? && !last_name.blank? &&
      Customer.where('email LIKE ? AND last_name LIKE ?', email.strip, last_name.strip).first
  end

  def self.match_first_last_and_address(first_name,last_name,street)
    !first_name.blank? && !last_name.blank? && !street.blank? &&
      Customer.where('first_name LIKE ? AND last_name LIKE ? AND street like ?', first_name, last_name, street).first
  end

  def self.match_uniquely_on_names_only(first_name, last_name)
    return nil if first_name.blank? || last_name.blank?
    m = Customer.where('last_name LIKE ? AND first_name LIKE ?',  last_name, first_name)
    m && m.length == 1 ?  m.first : nil
  end

  # If customer can be uniquely identified in DB, return match from DB
  # and fill in blank attributes with nonblank values from provided attrs.
  # Otherwise, create new customer.

  def self.find_or_create!(cust, loggedin_id=0)
    if (c = Customer.find_unique(cust))
      Rails.logger.info "Copying nonblank attribs for unique #{cust}\n from #{c}"
      c.copy_nonblank_attributes(cust)
      c.created_by_admin = true # ensure some validations are skipped
      txn = "Customer found and possibly updated"
    else
      c = cust
      Rails.logger.info "Creating customer #{cust}"
      txn = "Customer not found, so created"
    end
    c.force_valid = true      # make sure will pass validation checks
    # precaution: make sure email is unique.
    c.email = nil if (!c.email.blank? &&
      Customer.where('email like ?',c.email.downcase).first)
    c.save!
    Txn.add_audit_record(:txn_type => 'edit',
      :customer_id => c.id,
      :comments => txn,
      :logged_in_id => loggedin_id)
    c
  end

  # case-insensitive find by first & last name.  if multiple terms given,
  # all must match, though each term can match either first or last name
  def self.exact_name_matches(terms)
    conds =
      Array.new(terms.length, "(lower(first_name) LIKE ? or lower(last_name) LIKE ?)").join(' AND ')
    binds = terms.map { |w| [w.downcase, w.downcase] }
    Customer.regular_customers.where(*([conds,binds].flatten)).uniq.order('last_name')
  end

  def self.partial_name_matches(terms)
    conds =
      Array.new(terms.length, "(lower(first_name) LIKE ? or lower(last_name) LIKE ?)").join(' AND ')
    binds = terms.map { |w| ["%#{w.downcase}%", "%#{w.downcase}%"] }
    Customer.regular_customers.where(*([conds,binds].flatten)).uniq.order('last_name')
  end

  def self.other_term_matches(terms)
    conds = SEARCHABLE_COLUMNS.map { |c| "(lower(#{c}) LIKE ?)" }.join(" OR ")
    conds_ary = terms.map do |term|
      Array.new(SEARCHABLE_COLUMNS.size) { "%#{term.downcase}%" }
    end.flatten
    conds = Array.new(terms.size, conds).map{ |cond| "(#{cond})"}.join(" AND ")
    conds_ary.unshift(conds)
    Customer.regular_customers.where(conds_ary).uniq.order('last_name')
  end

  # Return value of field in this customer record that matches some term in an array of terms.
  # If multiple fields match, return any of the matching field values.
  def field_matching_terms(terms)
    match = Regexp.new(terms.map { |t| "(#{Regexp.escape t})" }.join("|"), Regexp::IGNORECASE)
    SEARCHABLE_COLUMNS.each do |attr|
      attr_val = self.send(attr)
      return attr_val if attr_val =~ match
    end
    ""
  end

end
