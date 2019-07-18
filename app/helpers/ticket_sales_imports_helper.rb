module TicketSalesImportsHelper

  def import_choices(io)
    oid = io.order.id
    c = io.customers.first
    if io.already_imported?
      link_to "View imported order", order_path(io.order)
    elsif io.must_use_existing_customer?
      (link_to(c.full_name, customer_path(c), :title => [c.email, c.day_phone, c.street].join(' ')) <<
        hidden_field_tag("o[#{oid}][customer_id]", c.id))
    elsif io.customers.empty?   # MUST create new
      content_tag('span', "Will create new customer")
      # if only 1 match, OR if there is an exact match and various near-matches, default is use match
    elsif (io.customers.length == 1  || # default = use exact match; MAY create new
        c.exact_name_match?(io.import_first_name, io.import_last_name))
      select_tag("o[#{oid}][customer_id]",
        (
          options_from_collection_for_select(io.customers, :id, :full_name_with_email_and_address, c.id) <<
          options_for_select([["Create new customer", ""]])
          ),
        :class => 'form-control')
    else            #       default = create new; other options exist
      select_tag("o[#{oid}][customer_id]",
        (
          options_for_select([["Create new customer", ""]], "Create new customer") <<
          options_from_collection_for_select(io.customers, :id, :full_name_with_email_and_address)
          ),
        :class => 'form-control')
    end
  end
  
end
