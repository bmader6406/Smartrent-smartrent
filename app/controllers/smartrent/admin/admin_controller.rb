require_dependency "smartrent/application_controller"
module Smartrent
  class Admin::AdminController < ApplicationController
    before_filter :authenticate_admin_user!
    layout "smartrent/admin"
  end
end
