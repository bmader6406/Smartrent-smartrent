module Smartrent
  class Admin::SessionsController < ::Devise::SessionsController
    layout "smartrent/admin"

  end
end

