A1.setupDatepicker = function() {
    var element = $('.daterangepicker');
    if (element.length < 1) { return; }
    // grab the element's data-config and use it for datepicker options.
    var options = JSON.parse(element.first().dataset.config);
    // startDate, endDate, and the 2 array elements of each slot in rawRanges must
    // be converted to something Moment will accept
    options.startDate = moment(options.startDate);
    options.endDate = moment(options.endDate);
    for (prop in options.ranges) {
        options.ranges[prop] = moment(options.ranges[prop]);
    }
    // enable the datepicker on the input field
    // and put the selected date range in the same input field
    
};


    
    
