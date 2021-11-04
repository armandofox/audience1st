A1.startTimer = function(timerExpirationField, timerDisplayField, expiredCallback) {
  var timerExpiresAt;
  var handler;
  
  if (timerExpirationField.length < 1) { return; } // field not present = order is done
  timerExpiresAt = Number(timerExpirationField.val()); // seconds since epoch, from Ruby
  $('.timer').removeClass('d-none');
  handler = setInterval(update, 1000);
  update();

  function update() {
    var now = (Date.now() / 1000) >> 0; // seconds since epoch; Date.now returns millisecs
    var diff = timerExpiresAt - now;
    if (diff < 0) {
      clearInterval(handler);
      expiredCallback.call();
    } else {
      var minutes = (diff / 60) >> 0; // coerce to integer
      var seconds = diff % 60;
      var timerString = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
      timerDisplayField.html(timerString);
      diff -= 1;
    };
  };
}
