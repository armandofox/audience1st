A1.warnZeroMaxSales = function(evt) {
  var maxSales = $('#showdate_max_advance_sales').val();
  if ((maxSales != '') && (Number(maxSales) == 0) &&
      !(confirm("You have set max sales to zero, which will prevent any tickets from being sold for this performance, regardless of other settings.  If this is really what you intended, click OK.  Otherwise click Cancel to make changes."))) {
    evt.preventDefault();
  }
};
    
A1.adjustShowdateType = function() {
  var perfType = $(this).val();
  var maxSalesDefault;
  function saveMaxSalesDefault() { $('#saved_max_sales').val($('#max_advance_sales').val()); }
  function restoreMaxSalesDefault() { $('#max_advance_sales').val($('#saved_max_sales').val()); }
  // hide/unset all fields, then selectively show/set the ones we need
  $('.Tt,.Tl,.Ts').addClass('d-none');
  // for the showdate checkboxes (Add/Change Redemptions), make them *disabled* to preserve
  // layout, and uncheck all the boxes whenever showdate type changes
  $('input[type=checkbox].showdate').prop('checked', false);
  $('.Ttd,.Tld,.Tsd').attr('disabled','disabled');
  $('#showdate_live_stream,#showdate_stream_anytime').val('');
  switch(perfType) {
  case 'Tt':                     // in theater
    restoreMaxSalesDefault();
    $('.Tt').removeClass('d-none');
    $('.Ttd').removeAttr('disabled');
    break;
  case 'Tl':                     // live stream
    saveMaxSalesDefault();
    $('#showdate_live_stream').val('1');
    $('.Tl').removeClass('d-none');
    $('.Tld').removeAttr('disabled');
    $('#max_advance_sales').val('');
    break;
  case 'Ts':                       // stream anytime
    saveMaxSalesDefault();
    $('#showdate_stream_anytime').val('1');
    $('.Ts').removeClass('d-none');
    $('.Tsd').removeAttr('disabled');
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
  $('.showdate-type').change(A1.adjustShowdateType).trigger('change');
  $('form.showdate-form').submit(A1.warnZeroMaxSales);
};

$(A1.showdateSetup);
