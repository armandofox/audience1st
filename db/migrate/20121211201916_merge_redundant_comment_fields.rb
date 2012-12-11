class MergeRedundantCommentFields < ActiveRecord::Migration
  def self.up
    # merge 'comment' into 'comments' 
    ActiveRecord::Base.connection.execute("UPDATE items SET comments=comment")
    remove_column :items, :comment
  end

  def self.down
  end
end
