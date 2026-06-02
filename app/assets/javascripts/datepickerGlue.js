A1.parseAndConvertDatesAndOptions = function(element) {
    var options = JSON.parse(element.dataset.config);
    // startDate, endDate, and the 2 array elements of each slot in rawRanges must
    // be converted to something Moment will accept
    options.startDate = moment(options.startDate);
    options.endDate = moment(options.endDate);
    for (prop in options.ranges) {
        // each range is a 2-element array of start and end date - convert to moment format
        options.ranges[prop][0] = moment(options.ranges[prop][0]);
        options.ranges[prop][1] = moment(options.ranges[prop][1]);
    }
    return(options);
}

A1.setupDatepicker = function(element) {
    // expects a jquery-wrapped element selector
    if (element.length < 1) {
        alert("No date picker found");
        return;
    }
    element = element.first();
    // grab the element's data-config and use it for datepicker options.
    var options = A1.parseAndConvertDatesAndOptions(element[0]);
    // enable the datepicker on the input field
    // and put the selected date range in the same input field

    element.daterangepicker(options)
};
// We don't call setupDatepicker since it is actually called each time
//   a daterangepicker field is created by DatesHelper#select_date_with_shortcuts
