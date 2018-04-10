module Smartrent
  class HourlyJob
    extend Resque::Plugins::Retry
    @retry_limit = RETRY_LIMIT
    @retry_delay = RETRY_DELAY

    def self.queue
      :crm_scheduled
    end

    def self.perform(time = Time.now.utc)
      time = Time.parse(time) if time.kind_of?(String)
      time = time.in_time_zone('Eastern Time (US & Canada)')

      if time.hour == 0
        Resque.enqueue(Smartrent::DailyResidentCreator, time)
      end
      
      if time.hour == 3
        Resque.enqueue(Smartrent::DailyHomeXmlImporter, time)
      end
      
      if time.wday == 0 && time.hour == 0 #Sunday of the current week
        # Resque.enqueue(Smartrent::WeeklyPropertyXmlImporter, time)
      end
    
      if time.day == 1 && time.hour == 4 #execute at the begining of month
        Resque.enqueue(Smartrent::MonthlyStatusUpdater, time.prev_month)

        # wait for MonthlyStatusUpdater executed
        Resque.enqueue_at(time + 3.hours, Smartrent::ResidentExporter, time.prev_month, "welcome")
        Resque.enqueue_at(time + 3.hours, Smartrent::ResidentExporter, time.prev_month, "monthly_move_in")
        
        if time.month == time.beginning_of_quarter.month
          # not needed
          # Resque.enqueue_at(time + 3.hours, Smartrent::ResidentExporter, time.prev_month, "quarterly_move_in")
          Resque.enqueue_at(time + 3.hours, Smartrent::ResidentExporter, time.prev_month, "statement")
        end

        #- app.hy.ly import should be run at midnight ET + 4hours
        #- email should be scheduled around 7AM ET
      end

    end
  end
end