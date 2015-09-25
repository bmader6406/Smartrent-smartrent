module Smartrent
  class DailyResidentCreator

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time = nil)
      time = Time.parse(time) if time.kind_of?(String)
      for_date = (time || Time.now).to_date
      
      pp "for_date: #{for_date}"
      
      ::Resident.where(:smartrent_resident_id => nil, "properties.move_in" => for_date).each do |r|
        r.properties.each do |p|
          pp "p.move_in: #{p.move_in}"
          p.send(:update_smartrent_resident) if p.move_in == for_date

        end
      end
      
    end # /perform
    
  end
end
