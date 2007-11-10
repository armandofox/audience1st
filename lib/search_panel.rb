#  Usage:
#  @searchpanel = SearchPanel.new(Customer, Customer.content_columns,
#                                :html_opts => {})
#  in view:
#  @searchpanel.render_each(field_prefix) do |label,name,selector,value|
#       <label for="<%=#{label}%>"><%=h name %></label><%= selector %><%=value%>
#  end
#  or:
#  @searchpanel.render_all(field_prefix)
#
#  in form processing action of controller:
#  qry = @searchpanel.sql_query(params, field_prefix)
#  Customer.find_by_sql(qry, :limit => whatever, etc.)
#

class SearchPanel < ActiveRecord::Base
  include ActionView::Helpers
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::TagHelper
  include Enumerable
  
  def initialize(klass, attribs=[], options={})
    @klass = klass
    @attribs = attribs
    @htmloptions = options[:html_options] || {}
    cols = klass.send('columns_hash')
    @render_with = {}
    @attribs.each do |a|
      c = a.to_s
      case cols[c].type
      when :integer,:float,:decimal
        choices = [["equals", c + ' = #{val}'],
                   ["does not equal", c + ' != #{val}'],
                   ["is less than", c + ' < #{val}'],
                   ["is greater than", c + ' > #{val}']]
      when :text,:string,:binary
        choices = [["is", c + ' LIKE \'#{val}\''],
                   ["begins with", ' LIKE \'#{val}%\''],
                   ["ends with", ' LIKE \'%#{val}\''],
                   ["contains", ' LIKE \'%#{val}%\'']]
      when :datetime,:date,:timestamp,:time
        choices = [["is", c + ' = #{val.strftime("%Y-%m-%d %H:%M:%S")}'],
                   ["is before", c + ' < #{val.strftime("%Y-%m-%d %H:%M:%S")}'],
                   ["is after" , c + ' > #{val.strftime("%Y-%m-%d %H:%M:%S")}']]
      when :boolean
        choices = [["is true", c + ' != 0'],
                   ["is false", c + ' = 0']]
      else
        choices = [["equals",         c + ' = \'#{val.to_s}\''],
                   ["does not equal", c + ' != \'#{val.to_s}\'']]
      end
      @render_with[c] = choices
    end
  end

  def renderwith
    @render_with
  end

  def render_each(prefix="")
    prefix += "_" unless prefix.empty?
    @render_with.each_pair do |c,opts|
      name = "#{prefix}#{c}"
      yield [name, 
             Inflector.humanize(c),
             select_tag("#{name}_sel", options_for_select(opts), @htmloptions),
             text_field_tag("#{name}_value")
            ]
    end
  end

  def render_all(options = {})
    result = ''
    pfx = options[:prefix]
    pfx += "_" unless pfx.empty?
    around_fieldset = options[:around_fieldset] || "%s"
    around_fields = options[:around_fields] || "%s"
    self.render_each(pfx) do |lbl,name,sel,text|
      str = ''
      if htmlclass.empty?
        result << "<div id='#{pfx}#{lbl}'>"
      else
        result << "<div id='#{pfx}#{lbl}' class='#{htmlclass}'>\n"
      end
      str << sprintf(around_field, "  <label for='#{lbl}'>#{name}</label>\n")
      str << sprintf(around_field, "  #{sel}\n")
      str << sprintf(around_field, "  #{text}\n")
      str << "</div>\n"
      result << sprintf(around_fieldset, str)
    end
    result
  end

  def sql_query(vals, use_and=true)
    qstr = "SELECT * FROM #{self.klass.send('table_name')} WHERE "
    joiner = use_and ? " AND " : " OR "
    conds = []
    vals.each_pair do |key,val|
      if val && !(val.to_s.empty?)
        # key is the column name
        eval_str = self.render[key.to_s]
        # val is now bound, so eval the string in context
        conds.push("(#{eval(eval_str)})")
      end
    end
    qstr += conds.join(joiner)
  end
end
