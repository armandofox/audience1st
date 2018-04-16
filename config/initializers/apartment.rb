# This code (from https://github.com/influitive/apartment/issues/508)
# works around Apartment gem issue
# https://github.com/zdennis/activerecord-import/issues/233 
# in which Rails' caching of the next-sequence-value for autoincrement
# keys may be wrong because the caching isn't aware of multiple
# tenants.  The workaround is to effectively disable caching of the
# sequence number.

if ActiveRecord::Base.connection.adapter_name.downcase =~ /postgres/
  Rails.logger.warn "#{__FILE__}:#{__LINE__}: Initializing workaround for Apartment gem issue 233"
  module PostgresqlSequenceResetter
    def connect_to_new(tenant=nil)
      super

      model_names = ActiveRecord::Base.descendants.map(&:to_s)

      tables = ActiveRecord::Base.connection.tables
        .map(&:singularize)
        .map(&:camelize)

      resettable_tables = tables & model_names

      resettable_tables.each do |table|
        table.constantize.reset_sequence_name
      end
    end
  end

  require "apartment/adapters/postgresql_adapter"
  Apartment::Adapters::PostgresqlSchemaAdapter.prepend PostgresqlSequenceResetter
end

# You can have Apartment route to the appropriate Tenant by adding some Rack middleware.
# Apartment can support many different "Elevators" that can take care of this routing to your data.
# Require whichever Elevator you're using below or none if you have a custom one.
#
# require 'apartment/elevators/generic'
# require 'apartment/elevators/domain'
# require 'apartment/elevators/subdomain'
require 'apartment/elevators/first_subdomain'
# require 'apartment/elevators/host'

#
# Apartment Configuration
#
Apartment.configure do |config|

  # Add any models that you do not want to be multi-tenanted, but remain in the global (public) namespace.
  # A typical example would be a Customer or Tenant model that stores each Tenant's information.
  #
  # config.excluded_models = %w{ Tenant }

  # In order to migrate all of your Tenants you need to provide a list of Tenant names to Apartment.
  # You can make this dynamic by providing a Proc object to be called on migrations.
  # This object should yield either:
  # - an array of strings representing each Tenant name.
  # - a hash which keys are tenant names, and values custom db config (must contain all key/values required in database.yml)
  #
  # config.tenant_names = lambda{ Customer.pluck(:tenant_name) }
  # config.tenant_names = ['tenant1', 'tenant2']
  # config.tenant_names = {
  #   'tenant1' => {
  #     adapter: 'postgresql',
  #     host: 'some_server',
  #     port: 5555,
  #     database: 'postgres' # this is not the name of the tenant's db
  #                          # but the name of the database to connect to before creating the tenant's db
  #                          # mandatory in postgresql
  #   },
  #   'tenant2' => {
  #     adapter:  'postgresql',
  #     database: 'postgres' # this is not the name of the tenant's db
  #                          # but the name of the database to connect to before creating the tenant's db
  #                          # mandatory in postgresql
  #   }
  # }
  # config.tenant_names = lambda do
  #   Tenant.all.each_with_object({}) do |tenant, hash|
  #     hash[tenant.name] = tenant.db_configuration
  #   end
  # end
  #
  # config.tenant_names = lambda { ToDo_Tenant_Or_User_Model.pluck :database }
  config.tenant_names = Figaro.env.tenant_names!.split(',')

  # By default, and only when not using PostgreSQL schemas, Apartment will prepend the environment
  # to the tenant name to ensure there is no conflict between your environments.
  # This is mainly for the benefit of your development and test environments.
  # Uncomment the line below if you want to disable this behaviour in production.
  #
  # config.prepend_environment = !Rails.env.production?
end

# Setup a custom Tenant switching middleware. The Proc should return the name of the Tenant that
# you want to switch to.
# Rails.application.config.middleware.use Apartment::Elevators::Generic, lambda { |request|
#   request.host.split('.').first
# }

Rails.application.config.middleware.use Apartment::Elevators::FirstSubdomain
# other Elevators choices: Domain, Subdomain, Host, Generic (w/callable arg that's passed the ActionDispatch.request obj)

