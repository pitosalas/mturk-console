class CreateHits < ActiveRecord::Migration
  def self.up
    create_table :hits do |t|
      # Title of the HIT
      t.column :title, :string, :null => false
      
      # Description
      t.column :description, :text, :null => false, :limit => 2000
      
      # A blog this hit was created for
      t.column :blogURL, :string, :null => false
      
      # Reward amount
      t.column :rewardAmount, :float, :null => false
      
      # Reward currency (ISO 4217 - http://en.wikipedia.org/wiki/ISO_4217)
      t.column :rewardCurrency, :string, :null => false, :limit => 3
      
      # Assignment duration in seconds
      t.column :assignmentDurationInSeconds, :integer, :null => false
      
      # HIT lifetime in seconds
      t.column :lifetimeInSeconds, :integer, :null => false
      
      # Keywords (comma-separated)
      t.column :keywords, :text, :limit => 1000
      
      # Maximum number of assignments possible for this HIT
      t.column :maxAssignments, :integer
      
      # Delay before the submission is automatically approved
      t.column :autoApprovalDelayInSeconds, :integer
      
      # Qualification requirements in internal format
      t.column :qualificationRequirements, :text
      
      # Hit ID
      t.column :hitId, :string, :limit => 20, :null => false

      # Hit type ID (same as group Id)
      t.column :typeId, :string, :limit => 20, :null => false
      
      # Sandbox / Production
      t.column :sandbox, :boolean, :null => false
    end
  end

  def self.down
    drop_table :hits
  end
end
