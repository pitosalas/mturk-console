class CreateSystemSettings < ActiveRecord::Migration
  def self.up
    create_table :system_settings do |t|
      t.column :name,   :string,  :null => false, :limit => 255
      t.column :value,  :text,    :null => false
    end

    add_index :system_settings, [:name], :unique => true

    # Initialize key data    
    SystemSetting.create(:name => 'Host', :value => 'Sandbox')
    SystemSetting.create(:name => 'AWSAccessKeyId', :value => '11JQ90M7E14PYZR30782')
    SystemSetting.create(:name => 'AWSAccessKey', :value => 'VAGuNjCzeNEa3/zel/eM2v8uUYsr+31s1TMwEqlb')
    SystemSetting.create(:name => 'ExternalQuestionXML', :value => 
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<% require 'cgi' %>\n" +
      "<ExternalQuestion xmlns=\"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2006-07-14/ExternalQuestion.xsd\">\n" +
      "  <ExternalURL>http://www.blogbridge.com/mturk/question.htm?url=<%= CGI::escape url %></ExternalURL>\n" +
      "  <FrameHeight>500</FrameHeight>\n" +
      "</ExternalQuestion>")
  end

  def self.down
    drop_table :system_settings
  end
end
