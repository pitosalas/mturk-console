class Hit < ActiveRecord::Base
  validates_presence_of     :title,
                            :description,
                            :blogURL,
                            :hitId,
                            :typeId,
                            :rewardAmount,
                            :rewardCurrency,
                            :assignmentDurationInSeconds,
                            :lifetimeInSeconds,
                            :sandbox

  validates_length_of       :description, :maximum => 2000
  validates_length_of       :keywords, :maximum => 1000, :allow_nil => true
  
  validates_numericality_of :rewardAmount
  validates_numericality_of :assignmentDurationInSeconds, :only_integer => true
  validates_numericality_of :lifetimeInSeconds, :only_integer => true
  validates_numericality_of :maxAssignments, :only_integer => true, :allow_nil => true
  
  protected
  def validate
    errors.add(:assignmentDurationInSeconds, "should be in range from 30 to 31536000 (356 days).") unless assignmentDurationInSeconds.nil? || (assignmentDurationInSeconds >= 30 && assignmentDurationInSeconds <= 31536000)
    errors.add(:lifetimeInSeconds, "should be in range from 30 to 31536000 (356 days).") unless assignmentDurationInSeconds.nil? || (lifetimeInSeconds >= 30 && lifetimeInSeconds <= 31536000)
    errors.add(:maxAssignments, "should be in range from 1 to 1000000000 (1 billion).") unless assignmentDurationInSeconds.nil? || (maxAssignments >= 1 && maxAssignments <= 1000000000)
    errors.add(:autoApprovalDelayInSeconds, "should be in range from 0 to 2592000 (30 days).") unless autoApprovalDelayInSeconds.nil? || (autoApprovalDelayInSeconds >= 0 && autoApprovalDelayInSeconds <= 2592000)
  end
end
