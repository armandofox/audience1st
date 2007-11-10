class PhplistUser < ActiveRecord::Base

  set_table_name "phplist_user_user"

  if (RAILS_ENV == 'production')
    establish_connection :phplist
  else
    establish_connection :phplist_dev
  end

  def self.create_phplist_list(custs, listid, args={})
    unless PhplistList.find_by_id(listid)
      raise "Invalid list ID"
    end
    case args[:clear]
    when :list, :all
      PhplistListuser.destroy(:conditions => "listid = #{listid.to_i}")
    when :users, :all
      PhplistUser.destroy_all
    end
    custs.select {|cust| cust.has_valid_email_address? }.map do |c|
      begin
        if (p = PhplistUser.find_by_email(c.login))
          PhplistListuser.create(:userid => p.id, :listid => listid)
        elsif  (p = PhplistUser.create(:email => c.login.strip,
                                       :foreignkey => cid,
                                       :confirmed => 1,
                                       :htmlemail => 1))
          PhplistListuser.create(:userid => p.id, :listid => listid)
        end
      rescue Exception => e
        logger.error("create_phplist_list: #{e.message}")
        return nil
      end
    end
    listid
  end
  
end
