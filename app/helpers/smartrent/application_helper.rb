module Smartrent
  module ApplicationHelper
    def number_to_currency(price)
      "$" + price.to_s
    end
  end
end
