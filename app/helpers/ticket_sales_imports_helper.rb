module TicketSalesImportsHelper

  def import_choices(order)
    io = order.from_import
    # :rails5: returns find() results in order that ids were provided, so the array sorting can be removed from the following line:
    customers = Customer.find(io.customer_ids).sort_by { |rec| io.customer_ids.index rec.id }
    # customers = Customer.find(io.customer_ids)
    c = customers.first

    # if email matches, MUST use existing customer

    if io.must_use_existing_customer
      rollover_with_contact_info(customers.first)

    # if NO matches, MUST create new customer
      
    elsif customers.empty?   # MUST create new
      content_tag('span', "Will create new customer")

    # if exactly 1 match, OR best match is name-exact, use that as default, but allow creating new

    elsif (customers.length == 1  || c.exact_name_match?(io.first, io.last))
      select_tag("customer_id[#{order.id}]",
        (options_from_collection_for_select(customers, :id, :full_name_with_email_and_address, c.id) <<
         options_for_select([["Create new customer", ""]])),
        :class => 'form-control')

    # otherwise, if multiple viable options exist, show all of them but default to 'create new'

    else
      select_tag("customer_id[#{order.id}]",
        (options_for_select([["Create new customer", ""]], "Create new customer") <<
         options_from_collection_for_select(customers, :id, :full_name_with_email_and_address)),
        :class => 'form-control')
    end
  end
end
