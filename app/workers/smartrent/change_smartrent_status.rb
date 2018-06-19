module Smartrent
  class ChangeSmartrentStatus

    def self.perform(resident_id)
    	time = Time.now
    	resident = Smartrent::Resident.includes(:rewards, :resident_properties).find_by_id resident_id
    	change_smartrent_status(resident, time) if resident
    end

    def self.live_in_smartrent_properties(resident, time)
    	live_in_properties = resident.resident_properties.
    																	select{|rp| 
    																		rp.move_out_date.blank? or 
    																		rp.move_out_date > time
    																	}
    	live_in_smartrent_properties = live_in_properties.
    																	select{|rp| 
    																		rp.property.is_smartrent 
    																	}
    end

    def self.smartrent_properties(resident)
    	smartrent_properties = resident.resident_properties.
    																		select{|rp| 
    																			rp.property.is_smartrent 
    																		}
    end

    def self.move_out_smartrent_properties(resident, time)
    	move_out_smartrent_properties = smartrent_properties(resident).select{|rp| 
    																		rp.move_out_date and 
    																		rp.move_out_date < time
																			}
    end

    def self.change_smartrent_status(resident, time)
    	if live_in_smartrent_properties(resident, time).present?
    		resident.smartrent_status = Smartrent::Resident::STATUS_ACTIVE
    		pp "change smartrent_status ===> #{resident.email} ,, Active"
    		resident.save
    		pp "change smartrent_status SAVED ===> #{resident.email}"
    	else
	    	if move_out_smartrent_properties(resident, time).present?
	    		max_move_out_date = move_out_smartrent_properties(resident, time).
	    													max_by{|rp| rp.move_out_date }.move_out_date
	    		if max_move_out_date.month == time.month && max_move_out_date.year == time.year
	    			resident.smartrent_status = Smartrent::Resident::STATUS_INACTIVE
	    			resident.expiry_date = time + 2.years
	    			pp "change smartrent_status ===> #{resident.email} ,, In-Active"
	    		else
	    			expiry_date = max_move_out_date + 2.years
	    			if expiry_date < time
	    				resident.smartrent_status = Smartrent::Resident::STATUS_EXPIRED
	    				pp "change smartrent_status ===> #{resident.email} ,, Expired"
	    			else
	    				resident.smartrent_status = Smartrent::Resident::STATUS_INACTIVE
	    				pp "change smartrent_status ===> #{resident.email} ,, In-Active"
	    			end
		    		resident.expiry_date = expiry_date
		    	end
		    	resident.save
		    	pp "change smartrent_status SAVED ===> #{resident.email}"
	    	end
	    end
    end

  end

end