class CreateQualificationRequests < ActiveRecord::Migration
  def self.up
    create_table :qualification_requests do |t|
      # Request ID
      t.column :request_id, :text, :null => false
      
      # Qualification type ID
      t.column :type_id, :string, :null => false
      
      # Worker ID
      t.column :subject_id, :string, :null => false
      
      # Structure with the question (QuestionForm)
      t.column :test, :text, :null => false
      
      # Structure with the answer (QuestionFormAnswers)
      t.column :answer, :text, :null => false
      
      # Date / time of submission
      t.column :submit_time, :datetime, :null => false
      
      # TRUE / FALSE / NULL (if not approved yet)
      t.column :approved, :boolean, :default => nil
    end
  end

  def self.down
    drop_table :qualification_requests
  end
end
