module GroupsMigrationHelper
  #c is the cutomer who may or may not have a company
  def migrate_company(c)
    if c.company != nil
      if Group.exists?(:name => c.company)
        puts("in here")
        g = Group.where(:name => c.company).first
      else
        g = Group.create(:name => c.company,
            :address_line_1 => c.company_address_line_1,
            :address_line_2 => c.company_address_line_2,
            :city => c.company_city,
            :state => c.company_state,
            :zip => c.company_zip,
            :work_phone => c.work_phone,
            :cell_phone => c.cell_phone,
            :work_fax => c.work_fax,
            :group_url => c.company_url,
            :best_way_to_contact => c.best_way_to_contact)
        puts("made")
      end
      puts(g)
      g.customers << c
      c.groups << g
    end
  end
end
