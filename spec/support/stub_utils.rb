module StubUtils

  # fake returning an option value
  def stub_option!(option, value)
    Option.stub(option).and_return(value)
  end

  def stub_month_and_day(month,day)
    stub_option!(:season_start_month, month)
    stub_option!(:season_start_day, day)
  end

  def stub_globals_and_userlevel(*userlevels)
    controller.stub!(:set_globals).and_return(true)
    userlevels.each { |u| controller.stub!("is_#{u}_filter").and_return(true) }
    controller.stub!(:is_logged_in).and_return(1)
    controller.stub!(:logged_in_id).and_return(1)
  end
  
end
