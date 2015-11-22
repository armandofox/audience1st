A1.vouchertype = {

  hide_price: function() {
    jQuery('#p_vouchertype_price').hide();   
    jQuery('#vouchertype_price').value = '0'; 
  },
  hide_walkup_sale: function()  {
    jQuery('#p_vouchertype_walkup_sale_allowed').hide(); jQuery('#vouchertype_walkup_sale_allowed').checked = false;  },
  hide_changeable: function() {
    jQuery('#vouchertype_changeable').checked = false;  jQuery('#p_vouchertype_changeable').hide(); },
  hide_account_code: function() {   jQuery('#p_vouchertype_account_code').hide();  },
  hide_availability: function() {   jQuery('#p_vouchertype_offer_public').hide();  },
  hide_subscriber: function()   {   
    jQuery('#vouchertype_subscription').checked = false ; jQuery('#p_vouchertype_subscription').hide();  },

  reset_fields: function() {
    var category = jQuery(this).val();
    var k = A1.vouchertype;
    console.log(category);
    jQuery('.vtform').show();
    switch(category)  {
    case 'bundle':
      k.hide_walkup_sale(); k.hide_changeable();
      break;
    case 'subscriber':
      k.hide_price(); k.hide_walkup_sale(); 
      k.hide_account_code(); k.hide_availability();
      break;
    case 'comp':
      k.hide_price(); k.hide_account_code(); 
      k.hide_subscriber();
      break;
    case 'nonticket':
      k.hide_changeable();
      break;
    case 'revenue':
      break;
    }
  },
  observe_vouchertype_field: function() {
    jQuery('#vouchertype_category').change(A1.vouchertype.reset_fields);
  }
};

jQuery(A1.vouchertype.observe_vouchertype_field);



