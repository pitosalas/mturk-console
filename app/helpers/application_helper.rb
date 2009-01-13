# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
end

# Upgrade SystemSetting class to accept SystemSetting['abc']='newval' notation
class SystemSetting
  def self.[]=(name, val)
    s = SystemSetting[name]
    s.value = val
    s.save
  end
end