require_dependency "smartrent/application_controller"
module Smartrent
  class Admin::AdminController < ApplicationController
    layout "smartrent/admin"
  end
end
