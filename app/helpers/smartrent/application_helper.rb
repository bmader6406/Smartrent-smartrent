module Smartrent
  module ApplicationHelper
    
    def sortable(column, title = nil)
      title ||= column.titleize
      column = column.to_s
      css_class = column == sort_column.split(".").last ? "current #{sort_direction}" : ""
      direction = column == sort_column.split(".").last && sort_direction == "asc" ? "desc" : "asc"
      
      if css_class == "current desc"
        title += " <i class='fa fa-caret-down'></i>"
      elsif css_class == "current asc"
        title += " <i class='fa fa-caret-up'></i>"
      end
      
      link_to raw(title), {:sort => column, :direction => direction}, {:class => css_class}
    end
    
  end
end
