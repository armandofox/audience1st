A1.checkout = {
  showCheckoutWarning: function() {
    var message = $('#checkout_message').val();
    if (message != '') {
      // delay showing the alert until whole page is loaded.  Ugh.
      window.onload(function() { alert(message); });
    }
  }
  ,startTimer: function() {
    var timerExpiresField = $('#timer_expires');
    if (timerExpiresField.length < 1) { return; } // field not present = order is done
    var timerExpiresAt = Number(timerExpiresField.val()); // seconds since epoch, from Ruby
    var now = (Date.now() / 1000) >> 0; // seconds since epoch; Date.now returns millisecs
    var diff = timerExpiresAt - now;
    var handler;
    if (diff > 0) {
      $('.timer').removeClass('d-none');
      handler = setInterval(updateTimer, 1000);
    } else {
      A1.checkout.timerExpired();
    };
    function updateTimer() {
      var minutes = (diff / 60) >> 0; // coerce to integer
      var seconds = diff % 60;
      var timerString = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
      $('#timer').html(timerString);
      diff -= 1;
      if (diff < 0) {
        diff = 0;               // we're done
        clearInterval(handler);
        A1.checkout.timerExpired();
      };
    };
  }
  ,timerExpired: function() {
    // show alert and cancel the order
    alert("Sorry, but you did not complete the order in time.  Your seats have been released.  Please restart your order.");
    window.location.replace('/store/cancel'); // replace makes current page inaccessible in History
  }
  ,setupForCheckout: function() {
    if ($('#cart').length > 0) {
      // on any page where in-progress order is displayed, show countdown timer
      A1.checkout.startTimer();
    }
    if ($('body#store_checkout').length > 0) {
      // on checkout page only, show checkout message
      A1.checkout.showCheckoutWarning();
    };
  }
};

$(A1.checkout.setupForCheckout);
