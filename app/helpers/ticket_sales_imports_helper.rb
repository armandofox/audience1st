module TicketSalesImportsHelper

  def import_choices(importable_order)
    options_for_select([["Do not import", ImportableOrder::DO_NOT_IMPORT],
        ["Create new customer", ImportableOrder::CREATE_NEW_CUSTOMER]])     <<
      options_from_collection_for_select(importable_order.customers, :id, :full_name)
  end

end
