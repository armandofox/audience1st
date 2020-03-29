A1.adjustHouseCap = function() {
  var chosenSeatmap = $(this);
  if (chosenSeatmap.val() == ''  &&  !A1.firstTrigger)    {  // general admission
    $('.showdate-house-capacity').val('').removeClass('.a1-passive-text-input').prop('readonly',false);
  } else {
    var capacity = chosenSeatmap.find('option:selected').text().match( /\(([0-9]+)\)$/ )[1];
    $('.showdate-house-capacity').val(capacity).addClass('.a1-passive-text-input').prop('readonly',true);
  }
  A1.firstTrigger = false;
};

// On pages that have a .showdate-house-capacity auto-updatable field, .showdate-seating-choices 
// will be the menu that triggers it
$(function() {
  A1.firstTrigger = true;
  $('.showdate-seating-choices').change(A1.adjustHouseCap).trigger('change');
});
