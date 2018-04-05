module YamlDb
  module SerializationHelper
    class Load
      def self.load(io, truncate=true)
        ActiveRecord::Base.connection.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL search_path = #{ENV['SCHEMA']};") if ENV['SCHEMA']
          load_documents(io, truncate)
        end
      end
    end
  end
end

