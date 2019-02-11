A1.hide_checkbox_setup = function() {
  $('.hide_checkbox').change(A1.hide_checkbox);
}
A1.hide_checkbox = function() {
  var elt = $(this);
  var selector = elt.data('selector');
  var action_if_checked = elt.data('ifchecked');
  if (elt.is(':checked')) {
    if (action_if_checked == 'hide') {
      $(selector).hide();
    } else {
      $(selector).show();
    }
  } else {
    if (action_if_checked == 'hide') {
      /* unchecked, so show all */
      $(selector).show();
    } else {
      /* unchecked, so hide all */ 
      $(selector).hide();
    }
  }
};

$(A1.hide_checkbox_setup);
