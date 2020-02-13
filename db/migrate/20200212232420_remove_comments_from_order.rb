class RemoveCommentsFromOrder < ActiveRecord::Migration
  def change
    orders = Order.where.not(:comments => [nil, '']).includes(:items)
    invalid = []
    item = nil
    Order.transaction do
      orders.each do |o|
        next unless (item = o.items.first)
        item.comments = "#{item.comments.to_s};#{o.comments}".split(/\s*;\s*/).uniq.join('; ').truncate(255)
        invalid.push(item.id) unless item.valid?
        item.save(:validate => false)
      end
      puts "Updated comments on #{orders.size} orders"
      puts "#{invalid.length} invalid items:"
      puts invalid.join(',')
      remove_column :orders, :comments
    end
  end
end

