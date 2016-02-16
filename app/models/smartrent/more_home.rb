module Smartrent
  class MoreHome < ActiveRecord::Base
    belongs_to :home
    
    has_many :floor_plan_images, :dependent => :destroy
    accepts_nested_attributes_for :floor_plan_images, :reject_if => lambda { |a| a[:image].blank? }, :allow_destroy => true
    
    validates :baths, :beds, :home_id, :sq_ft, :presence => true
    validates_numericality_of :baths, :beds
    
    before_create :set_position
    
    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Smartrent::Engine.root.to_path + "/data/more_homes.csv")
      end
      more_homes = SmarterCSV.process(f)
      more_homes.each do |home_hash|
        home_title = home_hash[:home_id]
        home = Home.find_by_title(home_title)
        if home
          home_hash[:home_id] = home.id
          create! home_hash
        end
      end
    end
    
    private
    
      def set_position
        if home
          h = self.class.unscoped.where("home_id = #{home.id}").group(:home_id).maximum(:position)
          max = h && h[home.id] || 0
          self.position = max + 1
        end
        
        true
      end
    
  end
end
