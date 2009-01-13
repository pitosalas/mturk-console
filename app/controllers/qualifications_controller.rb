class QualificationsController < ApplicationController

  # Lists qualifications
  def index
    @qualifications = Qualification.find(:all)
  end
  
  # Shows create qualification form
  def create_form
    @qualification = Qualification.new(
      :retryDelayInSeconds => 600,
      :qualificationIsActive => true,
      :testDurationInSeconds => 600,
      :autoGranted => false)
  end
  
  # Creates qualification
  def create
    @qualification = Qualification.new(params[:qualification])

    mt = MturkGateway.new
    res = mt.create_qualificaiton_type(@qualification)

    if res[:Created]
      if @qualification.save
        redirect_to :action => 'index'
      else
        render :action => 'create_form'
      end
    else
      @error = res[:Error]
      render :action => 'create_form'
    end
  end
  
  # Deletes qualification locally
  def delete
  end
  
  # Activates the qualification
  def activate
  end
  
  # Deactivates the qualification
  def deactivate
  end
  
  # Checks with MT if there are any submitted and unreviewed test results
  def poll_test_submissions
  end
end
