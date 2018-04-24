A1.hide_checkbox = function() {
  var elt = $(this);
  var selector = elt.data('selector');
  var action_if_checked = elt.data('ifchecked');
  if ($(self).is(':checked')) {
    if (action_if_checked == 'hide') {
      $.hide(selector);
    } else {
      $.show(selector);
    }
  } else {
    if (action_if_checked == 'hide') {
      /* unchecked, so show all */
      $.show(selector);
    } else {
      /* unchecked, so hide all */ 
      $.hide(selector);
    }
  }
};

$('.hide_checkbox').change(A1.hide_checkbox);
