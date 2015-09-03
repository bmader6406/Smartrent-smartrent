module Smartrent
  class HomeImporter

    def self.queue
      :crm_immediate
    end
  
    def self.perform(time = nil)
      for_date = (time || Time.now).to_date
      
      pp "for_date: #{for_date}"
      Home.import("")
    end # /perform
    
  end
end
