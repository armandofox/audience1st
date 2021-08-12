class CanceledItem < Item
  belongs_to :account_code
  def cancel!(by_whom) ; end # overridden from parent class

  def one_line_description(opts={}) ; attributes['comments'] ; end
  def description_for_report ; '(CANCELLED)' ; end
  def description_for_audit_txn ; attributes['comments'] ; end
  def comments ; '' ; end
  def item_description ; one_line_description ; end

  def cancelable? ; false ;  end
end
