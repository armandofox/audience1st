A1.hide_checkbox = function() {
  var elt = jQuery(self);
  var selector = elt.data('selector');
  var action_if_checked = elt.data('ifchecked');
  if (jQuery(self).is(':checked')) {
    if (action_if_checked == 'hide') {
      jQuery.hide(selector);
    } else {
      jQuery.show(selector);
    }
  } else {
    if (action_if_checked == 'hide') {
      /* unchecked, so show all */
      jQuery.show(selector);
    } else {
      /* unchecked, so hide all */ 
      jQuery.hide(selector);
    }
  }
};

jQuery('.hide_checkbox').change(A1.hide_checkbox);

