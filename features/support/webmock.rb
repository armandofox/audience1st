require 'webmock/cucumber'
WebMock.enable!
WebMock.disable_net_connect!(
  net_http_connect_on_start: true, # @see https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart
  allow_localhost: true,
  #  186585553: When upgrade to Ruby3.0, stop requiring webdrivers gem, upgrade to Selenium 4.11+,
  #   and hopefully remove the whitelist URIs below
  allow: [
    'https://storage.googleapis.com/chrome-for-testing-public',
    'googlechromelabs.github.io',
    'edgedl.me.gvt1.com',
    'https://messages.cucumber.io',
    /cucumber-messages-app-.*/
  ]
)

