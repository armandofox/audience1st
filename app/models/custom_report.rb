class CustomReport < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name
  
  # selected_clauses is a hash in which each key is the (symbolized)
  # name of a Clause and the corresponding value fills in the correct
  # param_type for that Clause.
  serialize :selected_clauses, Hash

  # selected_fields is an array of all the fields that should appear
  # in the output of this report
  serialize :selected_fields, Array

  def initialize(attrs=nil)
    super(attrs)
    self.clear_all_clauses
    self.clear_all_fields
  end

  def clear_all_clauses ; self.selected_clauses = {} ; end
  def clear_all_fields ; self.selected_fields = [] ; end

  # the default SQL template we start from
  @@select = "SELECT DISTINCT c.* FROM customers c " <<
    "JOIN vouchers v ON  v.customer_id = c.id " <<
    "JOIN vouchertypes vt ON v.vouchertype_id = v.id " <<
    "JOIN showdates sd ON v.showdate_id = sd.id " <<
    "JOIN shows s ON sd.show_id = s.id"

  require 'yaml'
  
  class Clause 
    
    attr_reader :name, :choices, :text, :param_type
    def initialize(name,choices,text,param_type)
      @name = name.to_sym
      @choices = choices.map { |h| h.symbolize_keys }
      @text = text
      @param_type = (param_type || "none").to_sym
    end
    unless defined?(@@clauses)
      @@clauses = []
      YAML.load_file("#{RAILS_ROOT}/app/models/custom_report_clauses.yml").each do |obj|
        @@clauses << 
          Clause.new(obj["name"], obj["choices"],obj["text"],obj["param_type"])
      end
    end
    
    def self.all_clauses
      @@clauses
    end

    def self.get(clause_name = "NONEXISTENT")
      n = clause_name.to_sym
      @@clauses.detect { |s| s.name == n }
    end
      
  end

  def self.all_clauses ; Clause.all_clauses; end
    
  def uses_clause?(clause)
    self.selected_clauses.has_key?(clause.to_sym)
  end

  def clause_values(clause)
    self.selected_clauses(clause.to_sym)
  end

  def uses_field?(fld)
    self.selected_fields.include?(fld.to_s)
  end

  def add_clause(clause, values=[])
    clause = clause.to_sym
    if (g = Clause.get(clause))
      self.selected_clauses[clause] = Hash[*(values.flatten)]
    else
      raise ArgumentError, "Nonexistent clause type '#{clause}'"
    end
  end

  def remove_clause(clause)
    self.selected_clauses.delete(clause.to_sym)
  end

  def add_field(fld)
    self.selected_fields << fld
  end

  # add various constraints to report

  def restrict_to_real_users 
    self.add_clause("c.role >= 0")
  end
  
  def order_by(what)
    @order = what.to_s
  end

  def sql_for_find
    sql = "#{@select}\n  WHERE " << @terms.map { |t| "(#{t})" }.join(" AND ")
    sql << " ORDER BY #{@order}" if @order
    return [sql] + @conds
  end
  
  def render_sql
    sql = "#{@select}<br/>  WHERE "
    sql << (@terms.empty? ?  "1"  :
            Customer.render_sql([@terms.map { |t| "(#{t})" }.join("<br/>   AND ")] <<
                                "<br/>  " << @conds))
    sql << " ORDER BY #{@order}" if @order
    # just a wrapper around ActiveRecord::Base.sanitize_sql
    sql
  end

end
