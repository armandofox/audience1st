A1.ticketSalesImport = {
  showMap: function(evt) {
    evt.preventDefault();
    
  }
  ,setup: function() {
    if ($('body#ticket_sales_import_edit').length > 0) {
      $('.select-seats').click(A1.ticketSalesImport.showMap);
    };
  }
};

$(A1.ticketSalesImport.setup);
