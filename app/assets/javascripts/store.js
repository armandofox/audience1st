A1.store = {
  adjustTicketMenus: function() {
    // first, recalculate the new total implied by this change.
    A1.recalc_store_total();
    
    // in case this was switching to zero tickets, start by enabling all menus/textboxes.
    $('.itemQty').prop('disabled', false);

    // if any vouchertypes with a nonblank zone have a nonzero qty of tickets,
    // DISABLE the selection of any vouchertypes whose zone does not match exactly.

    var theZone = zoneOfSelectedTickets();
    if (theZone == null) {      // zero tickets of any kind are selected
      $('#zone').val('');
      return;
    }
    $('#zone').val(theZone);
    $('.ticket').each(function() {
      if ($(this).data('zone') != theZone) {
        $(this).prop('disabled', true);
      }
    });
    function zoneOfSelectedTickets() {
      var zone = null;
      $('.itemQty').each(function() {
        var qty = parseInt($(this).val()) || 0;
        if (qty > 0) {              // found one
          zone = $(this).data('zone');
          return(false);        // breaks out of each()
        }
      });
      return(zone);
    }
  },
  setupStoreMenus: function() {
    if ($('body#store_index').length) { // only on Buy Tickets page
      $('.itemQty').change(A1.store.adjustTicketMenus);
    }
  }
};

$(A1.store.setupStoreMenus);
