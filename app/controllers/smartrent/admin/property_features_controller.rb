require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::PropertyFeaturesController < Admin::AdminController

    def import_page
      @active = "properties"
      render :import
    end
    def import
      PropertyFeature.import(params[:file])
      redirect_to admin_properties_path, notice: "Property Features have been imported"
    end
  end
end
