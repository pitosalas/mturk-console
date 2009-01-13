class SettingsController < ApplicationController
  # Saves settings
  def save
    params.each do |k, v|
      if k != 'action' && k != 'controller'
        SystemSetting[k] = v
      end
    end
  end
end
