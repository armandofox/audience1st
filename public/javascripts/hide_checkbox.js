A1.hide_checkbox = function() {
  var elt = jQuery(this);
  var affected_elts = jQuery(elt.data('selector'));
  var action_if_checked = elt.data('ifchecked');
  if (elt.is(':checked')) {
    if (action_if_checked == 'hide') {
      affected_elts.hide();
    } else {
      affected_elts.show();
    }
  } else {
    if (action_if_checked == 'hide') {
      /* unchecked, so show all */
      affected_elts.show();
    } else {
      /* unchecked, so hide all */ 
      affected_elts.hide();
    }
  }
};
addLoadEvent(function() {
  jQuery('.hide_checkbox').change(A1.hide_checkbox);
});
