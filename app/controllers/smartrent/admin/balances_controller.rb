require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::BalancesController < Admin::AdminController
    # GET /admin/balances
    # GET /admin/balances.json
    
    def index
      filter_balances
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @balances }
      end
    end
    
    def export
      exporter = BalanceExporter.init(params)

      respond_to do |format|
        format.js {
          if params[:recipient]
            Resque.enqueue(BalanceExporter, params)

          else
            @sendible = exporter.sendible?
          end
        }
        format.html {
          csv_string, file_name = exporter.generate_csv

          send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => file_name)
        }
      end
    end
    
    private
      
      def filter_balances(per_page = 20)
        arr = []
        hash = {}
        
        if params["status"].nil?
          params["status"] = "Active"
        end
        
        ["_id", "email", "first_name", "last_name", "status", "balance_min", "balance_max", "property_id", "activated"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          if k == "_id"
            arr << "id = :id"
            hash[:id] = "#{val}"
            
          elsif k == "status"
            arr << "smartrent_status = :#{k}"
            hash[k.to_sym] = "#{val}"
            
          elsif k == "property_id"
            arr << "smartrent_resident_properties.property_id = :#{k}"
            hash[k.to_sym] = "#{val}"
            
          elsif k == "balance_min"
            arr << "balance >= :#{k}"
            hash[k.to_sym] = "#{val.to_i}"

          elsif k == "balance_max"
            arr << "balance <= :#{k}"
            hash[k.to_sym] = "#{val.to_i}"
            
          elsif k == "first_name"
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
            
          elsif k == "last_name"
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
            
          elsif k == "activated" && params[k] == "true"
            arr << "confirmed_at IS NOT NULL"
            
          else
            arr << "#{k} = :#{k}"
            hash[k.to_sym] = "#{val}"
          end  
        end
        
        @balances = Smartrent::Resident.joins(:resident_properties).includes(:resident_properties => :property).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("if(first_name = '' or first_name is null,1,0),first_name asc")
      end

      def balance_params
        params.require(:balance).permit!
      end
  end
end
