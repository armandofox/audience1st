module AddOptionHelper

  def add_new_option(id,grp,name,value,typ)
    newopt = Option.create!(:grp => grp, :name => name, :value => value.to_s,
                           :typ => typ)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=#{id} WHERE id=#{newopt.id}")
  end
  module_function :add_new_option

end
