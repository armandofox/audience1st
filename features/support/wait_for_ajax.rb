module WaitForAjax
  def javascript_test?
    Capybara.current_driver == Capybara.javascript_driver
  end
  def wait_for_ajax
    return
    return unless javascript_test?
    Timeout.timeout(Capybara.default_max_wait_time) do
      1 until finished_all_ajax_requests?
    end
  end
  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end

World(WaitForAjax)
