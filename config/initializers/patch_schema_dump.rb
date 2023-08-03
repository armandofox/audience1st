# @see https://stackoverflow.com/questions/62570662/rails-4-ruby-2-7-1-schema-rb-shows-could-not-dump-table-because-of-following-f
module ActiveRecord
  module ConnectionAdapters
    module ColumnDumper
      def prepare_column_options(column, types)
        spec = {}
        spec[:name]      = column.name.inspect
        spec[:type]      = column.type.to_s
        spec[:null]      = 'false' unless column.null

        limit = column.limit || types[column.type][:limit]
        spec[:limit]     = limit.inspect if limit
        spec[:precision] = column.precision.inspect if column.precision
        spec[:scale]     = column.scale.inspect if column.scale

        default = schema_default(column).dup if column.has_default?
        spec[:default]   = default unless default.nil?

        spec
      end
    end
  end
end
