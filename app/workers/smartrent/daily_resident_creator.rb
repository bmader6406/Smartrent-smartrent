module Smartrent
  class DailyResidentCreator

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time = nil)
      time = Time.parse(time) if time.kind_of?(String)
      for_date = (time || Time.now).to_date
      
      pp "for_date: #{for_date}"
      
      ::Resident.where(:smartrent_resident_id => nil, "units.move_in" => for_date).each do |r|
        r.units.each do |u|
          pp "u.move_in: #{u.move_in}"
          u.send(:create_or_update_smartrent_resident) if u.move_in == for_date

        end
      end
      
    end # /perform
    
  end
end
