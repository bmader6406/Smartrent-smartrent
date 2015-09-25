module Smartrent
  class HomeImporter

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time = nil)
      time = Time.parse(time) if time.kind_of?(String)
      for_date = (time || Time.now).to_date
      
      pp "for_date: #{for_date}"
      Home.import("")
    end # /perform
    
  end
end
