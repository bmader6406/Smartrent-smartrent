module Smartrent
  class Article < ActiveRecord::Base
    attr_accessible :text, :title
  end
end
