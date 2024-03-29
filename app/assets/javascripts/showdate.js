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
  case 'Tl':                     // stream
    saveMaxSalesDefault();
    $('#showdate_live_stream').val('1');
    $('.Tl').removeClass('d-none');
    $('.Tld').removeAttr('disabled');
    $('#max_advance_sales').val('');
    break;
  case 'Ts':                       // stream on demand
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

A1.seatmapChangedForExistingPerformance = function() {
  var changingToNewSeatmap = ($(this).val() != '');
  function disableForm() {
    // disable everything so that basically the only choices are 'Save' or 'Dont Save'
    $('.form-control').prop('readonly', true);
    $('.showdate-seating-choices').find(':not(:selected)').prop('disabled',true);
    $('#showdate_thedate').find(':not(:selected)').prop('disabled',true);
  };
  function changeToGeneralAdmission() {
    // enable the House cap and Max advance sales fields if changing to Gen Adm
    $('#showdate_house_capacity, #showdate_max_advance_sales').prop('readonly', false);
    $('.house-seats-seatmap-changed').addClass('d-none');
    $('.house-seats-changing-to-general-admission').removeClass('d-none');
  };
  function changeToNewReservedSeating() {
    $('.house-seats-seatmap-changed').removeClass('d-none');
    $('.house-seats-changing-to-general-admission').addClass('d-none');
    $('#showdate_house_capacity, #showdate_max_advance_sales').prop('readonly', true);
  };
  $('#showdate_max_advance_sales').val($('.showdate-house-capacity').val());
  $('.house-seats-row').addClass('d-none');
  $('#seating-charts-wrapper').addClass('d-none');
  disableForm();
  changingToNewSeatmap ? changeToNewReservedSeating() : changeToGeneralAdmission();
  $('.submit').prop('disabled', false);
  $('#dont_save_changes').attr('href', window.location.href);
};

A1.seatmapChangedForNewPerformance = function() {
  var chosenSeatmap = $(this);
  // always clear out previously-chosen house seats (except when page is first loaded, as
  // it might be the Edit Showdate page; if it's the New Showdates page, the field
  // will be blank anyway).
  if (!A1.firstTrigger) {
    $('.showdate-house-seats').val('');
  }
  if (chosenSeatmap.val() == '') {  // general admission
    $('.house-seats-row').addClass('d-none');
    $('#seating-charts-wrapper').addClass('d-none');
    if (!A1.firstTrigger)    { 
      $('.showdate-house-capacity').val('').removeClass('.a1-passive-text-input').prop('readonly',false);
    }
  } else {
    // reserved seating: determine house cap from seatmap
    var capacity = chosenSeatmap.find('option:selected').text().match( /\(([0-9]+)\)$/ )[1];
    $('.showdate-house-capacity').val(capacity).addClass('.a1-passive-text-input').prop('readonly',true);
    $('.house-seats-row').removeClass('d-none');
    // blank out any current choices for house seats
    $('.showdate-house-seats').val('');
    // display seatmap for house seats selection
    A1.showSeatmapForHouseSeats();
  }
  A1.firstTrigger = false;
    
};

// On pages that have a .showdate-house-capacity auto-updatable field, .showdate-seating-choices 
// will be the menu that triggers it.  The following function therefore just affects the
// "add new performances" or "edit an existing performance" page.
A1.showdateSetup = function() {
  A1.firstTrigger = true;
  $('.showdate-seating-choices').change(A1.seatmapChangedForNewPerformance).trigger('change');
  if  ($('body#showdates_edit').length > 0) {
    // edit showdates page: changing seatmap freezes the UI until seatmap change confirmed
    $('.showdate-seating-choices').change(A1.seatmapChangedForExistingPerformance);
  } 
  $('.showdate-type').change(A1.adjustShowdateType).trigger('change');
  $('form.showdate-form').submit(A1.warnZeroMaxSales);
};

$(A1.showdateSetup);
