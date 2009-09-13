module Utils

  # fake returning an option value
  def stub_option!(option, value)
    Option.stub!(:value).with(option.to_sym).and_return(value)
  end

  def stub_month_and_day(month,day)
    stub_option!(:season_start_month, month)
    stub_option!(:season_start_day, day)
  end

end
