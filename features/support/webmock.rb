require 'webmock/cucumber'
WebMock.enable!
WebMock.disable_net_connect!(
  net_http_connect_on_start: true, # @see https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart
  allow_localhost: true,
  allow: "chromedriver.storage.googleapis.com")
