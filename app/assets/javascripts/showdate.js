A1.adjustShowdateType = function() {
  var perfType = $(this).val();
  var maxSalesDefault;
  function saveMaxSalesDefault() { $('#saved_max_sales').val($('#max_advance_sales').val()); }
  function restoreMaxSalesDefault() { $('#max_advance_sales').val($('#saved_max_sales').val()); }
  // hide/unset all fields, then selectively show/set the ones we need
  $('.Tt').addClass('d-none');
  $('.Tl').addClass('d-none');
  $('.Ts').addClass('d-none');
  $('#showdate_live_stream').val('');
  $('#showdate_stream_anytime').val('');
  switch(perfType) {
  case 'Tt':                     // in theater
    restoreMaxSalesDefault();
    $('.Tt').removeClass('d-none');
    break;
  case 'Tl':                     // live stream
    saveMaxSalesDefault();
    $('#showdate_live_stream').val('1');
    $('.Tl').removeClass('d-none');
    $('#max_advance_sales').val('');
    break;
  case 'Ts':                       // stream anytime
    saveMaxSalesDefault();
    $('#showdate_stream_anytime').val('1');
    $('.Ts').removeClass('d-none');
    $('#max_advance_sales').val('');
    break;
  default:
    alert("Unexpected error: unknown performance type: " + perfType);
  }
};

A1.adjustHouseCap = function() {
  var chosenSeatmap = $(this);
  if (chosenSeatmap.val() == '') {  // general admission
    if (!A1.firstTrigger)    { 
      $('.showdate-house-capacity').val('').removeClass('.a1-passive-text-input').prop('readonly',false);
    }
  } else {                      // reserved seating: determine house cap from seatmap
    var capacity = chosenSeatmap.find('option:selected').text().match( /\(([0-9]+)\)$/ )[1];
    $('.showdate-house-capacity').val(capacity).addClass('.a1-passive-text-input').prop('readonly',true);
  }
  A1.firstTrigger = false;
};

// On pages that have a .showdate-house-capacity auto-updatable field, .showdate-seating-choices 
// will be the menu that triggers it
A1.showdateSetup = function() {
  A1.firstTrigger = true;
  $('.showdate-seating-choices').change(A1.adjustHouseCap).trigger('change');
  $('.showdate-type').change(A1.adjustShowdateType);
};

$(A1.showdateSetup);
