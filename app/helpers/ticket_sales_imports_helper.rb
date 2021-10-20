module TicketSalesImportsHelper

  def import_choices(order)
    oid = order.id
    io = order.from_import
    customers = Customer.find(io.customer_ids)
    if io.must_use_existing_customer
      rollover_with_contact_info(customers.first)
    elsif customers.empty?   # MUST create new
      content_tag('span', "Will create new customer")
    else
      customer_list_options = options_from_collection_for_select(customers, :id, :full_name_with_email_and_address, customers.first.id)
      create_new_customer_option = options_for_select([["Create new customer", ""]], "Create new customer")
      if (customers.length == 1  || customers.first.exact_name_match?(io.first, io.last))
        # either just 1 match, OR exact match and various near-matches: allow create new
        menu_options = customer_list_options + create_new_customer_option
      else
        menu_options = create_new_customer_option + customer_list_options
      end
      select_tag("o[#{oid}][customer_id]", menu_options, :class => 'form-control')
    end
  end
end
