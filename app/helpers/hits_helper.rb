module HitsHelper

# Returns URL of a given HIT
def hit_url(hit)
  host = SystemSetting['Host'].value

  if host =~ /sandbox/i
    "http://workersandbox.mturk.com/mturk/preview?groupId=#{hit.typeId}" # Sandbox Url
  else
    "http://mturk.com/mturk/preview?groupId=#{hit.typeId}" # Production Url
  end
end

end
