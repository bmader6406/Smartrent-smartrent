module Smartrent
  class DailyResidentCreator

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time = nil)
      for_date = (time || Time.now).to_date
      
      pp "for_date: #{for_date}"
      
      ::Resident.where(:smartrent_resident_id => nil, "properties.move_in" => for_date).each do |r|
        r.properties.each do |p|
          
          p.send(:update_smartrent_resident) if p.move_in == for_date

        end
      end
      
    end # /perform
    
  end
end
