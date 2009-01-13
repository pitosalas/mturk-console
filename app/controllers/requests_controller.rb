class RequestsController < ApplicationController
  
  # Shows all pending qualification requests
  # currently present in the database
  def index
    @requests = QualificationRequest.find_non_reviewed
  end
  
  # The request to update current database by adding
  # pending qualification requests from AWS.
  # Upon completion, sends the updated list of requests.
  def update_from_aws
    # Update with new requests
    mt = MturkGateway.new
    begin
      resp = mt.get_new_qualification_requests
      
      # Check if there was an error
      @error = resp[:Error]
      if !@error.nil?
        render :action => 'error'
        return
      end
      
      # Save all new requests
      reqs = resp[:Requests]
      reqs.each { |r| r.save }
      
      # Render and return
      @requests = QualificationRequest.find_non_reviewed
      render :action => 'successful_update'
    rescue => e
      @error = e.message
      render :action => 'error'
    end
  end
  
  # Shows the page for a qualification request examination
  def examine
    begin
      @request = QualificationRequest.find(params[:id])
    rescue
      redirect_to :action => 'index'
    end
  end
  
  # Approves the request
  def approve
    approve_reject(params[:id], true)
  end
  
  # Rejects the request
  def reject
    approve_reject(params[:id], false)
  end

private

  # Approves or rejects
  def approve_reject(id, approve)
    begin
      r = QualificationRequest.find(id)

      # Contact MTurk
      mt = MturkGateway.new
      res = mt.approve_qualification_request(r, approve)
      
      if res[:Error].nil?
        r.approved = approve
        r.save
      end
    rescue
    ensure
      redirect_to :action => 'index'
    end
  end
end
