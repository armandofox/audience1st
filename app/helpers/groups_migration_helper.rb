module GroupsMigrationHelper
  #c is the cutomer who may or may not have a company
  def migrate_company(c)
    if c.company != nil
      if Company.exists?(:name => c.company)
        g = Company.where(:name => c.company).first
      else
        g = Company.create(:name => c.company,
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
      end
      g.customers << c
    end
  end
end
