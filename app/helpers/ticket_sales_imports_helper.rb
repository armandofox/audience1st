module TicketSalesImportsHelper

  def import_choices(io)
    oid = io.order.id
    if io.action == ImportableOrder::ALREADY_IMPORTED
      link_to "Previously imported", order_path(io.order)
    elsif io.action == ImportableOrder::MUST_USE_EXISTING_CUSTOMER
      c = io.customers.first
      (link_to(c.full_name, customer_path(c), :title => [c.email, c.day_phone, c.street].join(' ')) <<
        hidden_field_tag("o[#{oid}][customer_id]", c.id))
    elsif io.customers.empty?   # MUST create new
      content_tag('span', "Will create new customer")
    else                        # MAY create new; other candidates exist
      select_tag("o[#{oid}][customer_id]",
        (options_for_select([["Create new customer", ""]]) <<
          options_from_collection_for_select(io.customers, :id, :full_name_with_email_and_address)),
        :class => 'form-control')
    end
  end
  
end
