A1.themeOn = function() {
  $('#content').removeClass('a1-plain').addClass('themed');
};

/* If called with string argument, make that tab active. Otherwise, it's being called
   as a document-ready function, so make the tab corresponding to body's ID active. */

A1.setActiveTab = function(sel) {
  // var sel = "#t_reports_index";
  if (! (typeof(sel) == "string")) {
    var bodyId = $('body')[0].id;
    sel = 'li#t_' + bodyId;
  }
  $(sel).addClass('active');
};
    
/* On all page loads, set default active tab.  Individual pages may override it. */

$(A1.setActiveTab); 
