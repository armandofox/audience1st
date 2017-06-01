// after user clicks "Ready to swipe" button, move focus to
// hidden swipe-data field and change the message.  Set handler
// to do AJAX call to process swipe data on \n. If no swipe
// after 10 secs, go back to original state.
A1.waitForSwipe = function() {
    var timeout = 8;            // in seconds
    $('#ccReady').style.display = 'none';
    $('#ccWaiting').style.display = 'block';
    $('#swipe_data').value = '';
    $('#swipe_data').focus();
    setTimeout('A1.resetSwipe()', 1000*timeout);
}
A1.resetSwipe = function() {
    $('#ccWaiting').style.display = 'none';
    $('#ccReady').style.display = 'block';
    $('#credit_card_verification_value').focus();
}

// convert swipe data to form fields
A1.parseSwipeData = function() {
    var swipe = $('#swipe_data').val();
    var trk1 = /^%B(\d{1,19})\^([^/]+)\/([^/^]+)\^(\d\d)(\d\d)/;
    var trk2 = /;(\d{1,19})=(\d\d)(\d\d).{3,12}\?/;
    var elts;
    if (elts = swipe.match(trk1)) {
      $('#credit_card_number').val(elts[1]);
      $('#credit_card_last_name').val(elts[2].replace(/^\s+|\s+$/g, ''));
      $('#credit_card_first_name').val(elts[3].replace(/^\s+|\s+$/g, ''));
      setSelectedYear('credit_card_year', 2000+Number(elts[4]));
      $('#credit_card_month').selectedIndex = Number(elts[5]) - 1;
    } else if (elts = swipe.match(trk2)) {
      $('#credit_card_number').val(elts[1]);
      setSelectedYear('#credit_card_year', 2000+Number(elts[2]));
      $('#credit_card_month').selectedIndex = Number(elts[3]) - 1;
      $('#credit_card_last_name').val('');
      $('#credit_card_first_name').val('');
    } else {
      $('#credit_card_number').val('ERROR');
      $('#credit_card_last_name').val('ERROR');
      $('#credit_card_first_name').val('ERROR');
    }
    A1.resetSwipe();
    return false;
}

A1.setSelectedYear = function(elt_id, val) {
  var elt = $(elt_id);
  for (var i=0; i < elt.length ; i++) {
    if (val == Number(elt[i].value))
      elt.selectedIndex = i;
  }
}
