require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::BalancesController < Admin::AdminController
    helper_method :sort_column, :sort_direction
    
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
        
        ["_id", "email", "first_name", "last_name", "status", "balance_min", "balance_max", "move_in_min", "move_in_max", "property_id", "activated", "subscribed"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          if k == "_id"
            arr << "smartrent_residents.id = :id"
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
            
          elsif k == "move_in_min" && (Date.parse(val) rescue nil)
            arr << "first_move_in >= :#{k}"
            hash[k.to_sym] = Date.parse(val).to_s(:db)

          elsif k == "move_in_max" && (Date.parse(val) rescue nil)
            arr << "first_move_in <= :#{k}"
            hash[k.to_sym] = Date.parse(val).to_s(:db)
            
          elsif k == "first_name"
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
            
          elsif k == "last_name"
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
            
          elsif k == "email" && (!val.include?("@") || val.start_with?("@"))
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
            
          elsif k == "activated" && params[k] == "true"
            arr << "confirmed_at IS NOT NULL"
            
          elsif k == "subscribed" && params[k] == "true"
            arr << "subscribed = 1"
            
          else
            arr << "#{k} = :#{k}"
            hash[k.to_sym] = "#{val}"
          end  
        end
        
        @balances = Smartrent::Resident.joins(:resident_properties)
          .distinct("smartrent_residents.id")
          .includes(:resident_properties => :property)
          .where(arr.join(" AND "), hash)
          .paginate(:page => params[:page], :per_page => per_page)
          .order("#{sort_column} #{sort_direction}")
          
          #.order("if(first_name = '' or first_name is null,1,0),first_name asc")
      end

      def balance_params
        params.require(:balance).permit!
      end
      
      def sort_column
        params[:sort] ? params[:sort] : "if(first_name = '' or first_name is null,1,0),first_name"
      end

      def sort_direction
        %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
      end
      
  end
end
