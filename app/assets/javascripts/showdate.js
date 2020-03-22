A1.adjustHouseCap = function() {
  var menu = $(this);
  var seatmapId = menu.val();
  if (seatmapId == '')    {  // general admission
    $('.showdate-house-capacity').val('').removeClass('.a1-passive-text-input').prop('readonly',false);
  } else {
    var seatmapCap = menu.text().match( /\(([0-9]+)\)$/ )[1];
    $('.showdate-house-capacity').val(seatmapCap).addClass('.a1-passive-text-input').prop('readonly',true);
  }
};

// On pages that have a .showdate-house-capacity auto-updatable field, .showdate-seating-choices 
// will be the menu that triggers it
$(function() {
  $('.showdate-seating-choices').change(A1.adjustHouseCap).trigger('change');
});
