// after user clicks "Ready to swipe" button, move focus to
// hidden swipe-data field and change the message.  Set handler
// to do AJAX call to process swipe data on \n. If no swipe
// after 10 secs, go back to original state.
function waitForSwipe() {
    var timeout = 8;            // in seconds
    $('ccReady').style.display = 'none';
    $('ccWaiting').style.display = 'block';
    $('swipe_data').value = '';
    $('swipe_data').focus();
    setTimeout('resetSwipe()', 1000*timeout);
}
function resetSwipe() {
    $('ccWaiting').style.display = 'none';
    $('ccReady').style.display = 'block';
    $('credit_card_verification_value').focus();
}

// convert swipe data to form fields
function parseSwipeData() {
    swipe = $('swipe_data').getValue();
    var trk1 = /^%B(\d{1,19})\^([^/]+)\/([^/^]+)\^(\d\d)(\d\d)/;
    var trk2 = /;(\d{1,19})=(\d\d)(\d\d).{3,12}\?/;
    var elts;
    if (elts = swipe.match(trk1)) {
      $('credit_card_number').setValue(elts[1]);
      $('credit_card_last_name').setValue(elts[2].replace(/^\s+|\s+$/g, ''));
      $('credit_card_first_name').setValue(elts[3].replace(/^\s+|\s+$/g, ''));
      setSelectedYear('credit_card_year', 2000+Number(elts[4]));
      $('credit_card_month').selectedIndex = Number(elts[5]) - 1;
    } else if (elts = swipe.match(trk2)) {
      $('credit_card_number').setValue(elts[1]);
      setSelectedYear('credit_card_year', 2000+Number(elts[2]));
      $('credit_card_month').selectedIndex = Number(elts[3]) - 1;
      $('credit_card_last_name').setValue('');
      $('credit_card_first_name').setValue('');
    } else {
      $('credit_card_number').setValue('ERROR');
      $('credit_card_last_name').setValue('ERROR');
      $('credit_card_first_name').setValue('ERROR');
    }
    resetSwipe();
    return false;
}

function setSelectedYear(elt_id, val) {
  elt = $(elt_id);
  for (var i=0; i < elt.length ; i++) {
    if (val == Number(elt[i].value))
      elt.selectedIndex = i;
  }
}
