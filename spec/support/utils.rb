module Utils

  def stub_option!(option, value)
    Option.stub!(:value).with(option.to_sym).and_return(value)
  end
  
end
