module EmailListHelper

  def options_for_sublists(sublists=[])
    options_for_select(sublists.map do |name,count|
        [h("#{name} (#{count} members)"), h(name)]
      end)
  end

end
