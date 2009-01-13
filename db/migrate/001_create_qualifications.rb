class CreateQualifications < ActiveRecord::Migration
  def self.up
    create_table :qualifications do |t|
      # Qualification name visible to workers and requesters.
      t.column :name, :string, :null => false

      # Qualification description displayed when users examine it.
      t.column :description, :text, :null => false

      # Comma-separated list of keywords characterizing this qual.
      t.column :keywords, :string, :limit => 1000

      # Amount of time to wait before tests. 
      # If not specified -- no waiting.
      t.column :retryDelayInSeconds, :integer

      # Activity state.
      # TRUE - available for tests, 
      # FALSE - unavailable but valid.
      t.column :qualificationIsActive, :boolean, :null => false, :default => false

      # XML in QuestionForm format. 
      # If omitted, qualification is auto-granted.
      t.column :testXML, :text

      # XML in AnswerKey format. 
      # If given, automatic checks; if not, manual polling.
      t.column :answerKeyXML, :text

      # Max amount of time for taking a test. 
      # If not submitted before expiration -- voided.
      t.column :testDurationInSeconds, :integer

      # If TRUE, qualifications are granted immediately. 
      # Can't have :testXML and :autoGranted at the same time.
      t.column :autoGranted, :boolean, :null => false, :default => false

      # The value of the qualification that is automatically granted.
      t.column :autoGrantedValue, :integer
      
      # --- System fields ---

      # Flag shows that a qualification is System and can't be modified
      t.column :isSystemQualification, :boolean, :null => false, :default => false

      # Flag shows that the value should be of a Locale type
      t.column :isLocaleValue, :boolean, :null => false, :default => false
      
      # --- Response fields ---
      
      # ID the type receives when is created
      t.column :qualificationTypeId, :string
      
      # The date / time of the type creation
      t.column :creationTime, :datetime
    end
    
    Qualification.create(:qualificationTypeId => '00000000000000000000',
      :name => 'Worker_PercentAssignmentsSubmitted',
      :description => 'The percentage of assignments the Worker has submitted, over all assignments the Worker has accepted. The value is integer between 0 and 100.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true)

    Qualification.create(:qualificationTypeId => '00000000000000000070',
      :name => 'Worker_PercentAssignmentsAbandoned',
      :description => 'The percentage of assignments the Worker has abandoned, over all assignments the Worker has accepted. The value is integer between 0 and 100.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true)

    Qualification.create(:qualificationTypeId => '000000000000000000E0',
      :name => 'Worker_PercentAssignmentsReturned',
      :description => 'The percentage of assignments the Worker has returned, over all assignments the Worker has accepted. The value is integer between 0 and 100.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true)

    Qualification.create(:qualificationTypeId => '000000000000000000L0',
      :name => 'Worker_PercentAssignmentsApproved',
      :description => 'The percentage of assignments the Worker has submitted that were subsequently approved by the Requester, over all assignments the Worker has submitted. The value is integer between 0 and 100.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true)

    Qualification.create(:qualificationTypeId => '000000000000000000S0',
      :name => 'Worker_PercentAssignmentsRejected',
      :description => 'The percentage of assignments the Worker has submitted that were subsequently rejected by the Requester, over all assignments the Worker has accepted. The value is integer between 0 and 100.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true)

    Qualification.create(:qualificationTypeId => '00000000000000000071',
      :name => 'Worker_Locale',
      :description => 'The location of the Worker, as specified in the Worker\'s mailing address.',
      :qualificationIsActive => true,
      :testDurationInSeconds => 1,
      :isSystemQualification => true,
      :isLocaleValue => true)
  end

  def self.down
    drop_table :qualifications
  end
end
