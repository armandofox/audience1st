namespace :a1client do
  namespace :db do

    desc 'In preparation for importing to tenant TO, dump contents of tenant FROM (schema) on APP (Heroku app name) into ${TO}.pgdump, renaming all schema references to TO for importing to a destination schema (which must not already exist)'
    task :dump => :environment do
      raise 'FROM is required' unless (from = ENV["FROM"])
      raise 'TO is required' unless (to = ENV["TO"])
      raise 'APP is required' unless (app = ENV["APP"])
      sed = %Q{sed -e 's/#{from};/#{to};/g' -e 's/#{from}\./#{to}./g' -e 's/"#{from}"\./"#{to}"./g'  }
      cmd = %Q{heroku run pg_dump -Fp --inserts --no-privileges --no-owner '$DATABASE_URL' --schema=#{from} -a #{app} } <<
            %Q{ | #{sed}  > #{to}.pgdump } 
      puts cmd
      if system(cmd)
        puts "#{to}.pgdump created"
      else
        puts "Error: #{$?}"
      end
    end

    desc 'Upload contents of FILE into tenant schema TENANT (which must not already exist) on APP (Heroku app name)'
    raise 'APP is required' unless (app = ENV["APP"])
    raise 'FILE is required' unless (app = ENV["FILE"])
    task :upload => :environment do
      cmd = %Q{heroku pg:psql -a 
    end      

  end
end
