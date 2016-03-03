module Smartrent
  class ResidentCreator
    def self.queue
      :crm_immediate
    end
  
    def self.perform(resident_id, unit_id)
      resident = ::Resident.find(resident_id)
      unit = resident.units.find(unit_id)

      # Initialize by email is better than crm_resident_id
      # because the id "link" will be broken when the user do the full upload, result in duplicated sr resident
      sr = Smartrent::Resident.find_or_initialize_by(email: resident.email)
      sr.email = resident.email
      sr.first_name = resident.first_name
      sr.last_name = resident.last_name
      sr.crm_resident_id = resident.id.to_i # link smartrent resident with crm resident
      
      sr.save(:validate => false)
      
      sr_property = sr.resident_properties.find_or_initialize_by(property_id: unit.property_id, unit_code: unit.unit_code)
      sr_property.status = unit.status
      sr_property.move_in_date = unit.move_in
      sr_property.move_out_date = unit.move_out
      sr_property.save
      
      if sr_property.status == Smartrent::ResidentProperty.STATUS_CURRENT
        sr.update_attributes(:current_property_id => unit.property_id, :current_unit_id => unit.unit_id)
      end
      
      Smartrent::MonthlyStatusUpdater.set_status(sr)
    end
    
  
  end
end