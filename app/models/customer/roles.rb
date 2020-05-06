class Customer < ActiveRecord::Base
  # Values of the role field:
  # Roles are cumulative, ie higher privilege level can do everything
  # the lower levels can do.
  # < 10  regular user (customer)
  # at least 10 - board/staff member (can view/make reports, but not reservations)
  # at least 20 - box office user
  # at least 30 - box office manager
  # at least 100 - God ('admin')

  PRIVS = { 'patron' => 0, 'staff' => 10, 'walkup' => 15, 'boxoffice' => 20, 'boxoffice_manager' => 30, 'admin' => 100}
  PRIV_VALS = PRIVS.invert.sort.reverse

  def is_staff ; role >= PRIVS['staff'] ; end
  def is_walkup ; role >= PRIVS['walkup'] ; end
  def is_boxoffice ; role >= PRIVS['boxoffice'] or self == Customer.boxoffice_daemon ; end
  def is_boxoffice_manager ; role >= PRIVS['boxoffice_manager'] ; end
  def is_admin ; role >= PRIVS['admin'] ; end

  def self.roles
    PRIVS.keys
  end

  def self.role_value(role)
    PRIVS[role.to_s.downcase] || 0
  end

  def self.role_name(rval)
    r = rval.to_i
    if r > 30 then 'admin'
    elsif r >= 30 then 'boxoffice_manager'
    elsif r >= 20 then 'boxoffice'
    elsif r >= 15 then 'walkup'
    elsif r >= 10 then 'staff'
    else 'patron'
    end
  end

  def role_name
    Customer.role_name(self.role)
  end

  def role_value
    Customer.role_value(self.role)
  end
  
  # you can grant someone else a particular role as long as it's less
  # than your own.

  def can_grant(newrole)
    # TBD should really check that the two are
    # in different role-equivalence classes
    self.role >= Customer.role_value(newrole)
  end

end
