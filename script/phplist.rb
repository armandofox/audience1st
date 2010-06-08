

matched = 0
news = 0
errs = 0
cs = Customer.find(:all, :conditions => 'phplist_user_id IS NULL or phplist_user_id = 0')
cs.each do |c|
  if c.email.valid_email_address?
    c.phplist_user_id,msg = PhplistUser.find_or_create(c.email)
    if msg.match(/Linked/)
      matched += 1
    elsif msg.match(/Created/)
      news += 1
    else
      errs += 1
    end
  end
end

puts("#{news} created, #{matched} existing, #{errs} errors, #{news+matched+errs} total, #{cs.length} records")

