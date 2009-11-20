# various preconditions we use during Spec tests

module Utils
  
  def stub_globals_and_userlevel(*userlevels)
    controller.stub!(:set_globals).and_return(true)
    userlevels.each { |u| controller.stub!("is_#{u}_filter").and_return(true) }
    controller.stub!(:logged_in_id).and_return(1)
  end

end
