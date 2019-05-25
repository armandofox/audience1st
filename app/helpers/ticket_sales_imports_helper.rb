module TicketSalesImportsHelper

  def import_choices(importable_order)
    opts = ''
    if importable_order.action == ImportableOrder::USE_EXISTING_CUSTOMER
      opts << options_for_select[[importable_order.customers.first.full_name, ImportableOrder::USE_EXISTING_CUSTOMER]]
    else                        # OK to create new
      opts <<
        options_for_select([["Create new customer", ImportableOrder::CREATE_NEW_CUSTOMER]]) <<
        options_from_collection_for_select(importable_order.customers, :id, :full_name)
    end
    opts << options_for_select([["Do not import", ImportableOrder::DO_NOT_IMPORT]])
    opts.html_safe
  end

end
