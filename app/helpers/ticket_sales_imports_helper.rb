module TicketSalesImportsHelper

  def import_choices(order)
    oid = order.id
    io = order.from_import
    customers = Customer.find(io.customer_ids)
    if order.must_use_existing_customer?
      rollover_with_contact_info(customers.first)
    elsif customers.empty?   # MUST create new
      content_tag('span', "Will create new customer")
    elsif (customers.length == 1  || customers.first.exact_name_match?(io.first, io.last))
      # either just 1 match, OR exact match and various near-matches: allow create new
      select_tag("o[#{oid}][customer_id]", # default is use match 
                 (options_from_collection_for_select(customers, :id, :full_name_with_email_and_address, customers.first.id) <<
                  options_for_select([["Create new customer", ""]])),
                 :class => 'form-control')
    else            #       default = create new; other options exist
      select_tag("o[#{oid}][customer_id]",
                 (options_for_select([["Create new customer", ""]], "Create new customer") <<
                  options_from_collection_for_select(customers, :id, :full_name_with_email_and_address)),
                 :class => 'form-control')
    end
  end
end
