module ApplicationHelper
  
  def function_to_add_fields(name, f, association, selector)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    "#{association}.add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\", \"#{selector}\");"
  end

end
