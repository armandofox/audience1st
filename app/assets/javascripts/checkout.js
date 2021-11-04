A1.checkout = {
  showCheckoutWarning: function() {
    var message = $('#checkout_message').val();
    if (message != '') {
      // delay showing the alert until whole page is loaded.  Ugh.
      $(window).load(function() { alert(message); });
    }
  }

  ,timerExpired: function() {
    // show alert and cancel the order
    alert("Sorry, but you did not complete the order in time.  Your seats have been released.  Please restart your order.");
    window.location.replace('/store/cancel'); // replace makes current page inaccessible in History
  }

  ,setupForCheckout: function() {
    if ($('#cart').length > 0) {
      // on any page where in-progress order is displayed, show countdown timer
      A1.startTimer($('#timer_expires'), $('#timer'), A1.checkout.timerExpired);
    }
    if ($('body#store_checkout').length > 0) {
      // on checkout page only, show checkout message
      A1.checkout.showCheckoutWarning();
    };
  }
};

$(A1.checkout.setupForCheckout);
