module GroupsMigrationHelper
  def migrate_company(cust)
    if cust.company != nil
      if Company.exists?(:name => cust.company)
        g = Company.where(:name => cust.company).first
      else
        g = Company.create(:name => cust.company,
            :address_line_1 => cust.company_address_line_1,
            :address_line_2 => cust.company_address_line_2,
            :city => cust.company_city,
            :state => cust.company_state,
            :zip => cust.company_zip,
            :work_phone => cust.work_phone,
            :cell_phone => cust.cell_phone,
            :work_fax => cust.work_fax,
            :group_url => cust.company_url,
            :comments => cust.best_way_to_contact)

      end
      g.customers << cust
      return g
    end
  end
end
