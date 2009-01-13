class HitsController < ApplicationController
  # Lists HITs
  def index
    @hits = Hit.find(:all)
  end

  # Shows HITs creation form
  def create_hits_form
    @hit = Hit.new(
      :rewardAmount => 0.05,
      :lifetimeInSeconds => 3600 * 24 * 7,
      :autoApprovalDelayInSeconds => 3600 * 24,
      :assignmentDurationInSeconds => 60 * 5,
      :maxAssignments => 3)
  end

  # Creates multiple HITs
  def create_hits
    @hit = Hit.new(params[:hit])
    @links = params[:links].split(/\r*\n/)
    
    begin
      mt = MturkGateway.new
      res = mt.create_hits(@hit, @links, params_to_qualifications(params))
      @error = []
      
      if res[:Error].size != 0
        @error = res[:Error]
      else
        @created = res[:Created].size
        res[:Created].each do |hit|
          if !hit.save
puts hit.inspect
            @error << hit.errors.to_s
          end
        end
      end
  
      index
      render :action => 'index'
    rescue => e
      @error = e.message
puts e.inspect
      render :action => 'create_hits_form'
    end
  end
  
  private

  # Converts form parameters into the list of qualifications
  def params_to_qualifications(params)
    quals = []

    # Build two arrays of operations and values for all qualifications
    qo = {}
    qv = {}
    params.each do |k, v|
      if /(qo|qv)_([0-9A-Z]{20})/ =~ k
        # operation or value
        fl = Regexp.last_match(1)
        id = Regexp.last_match(2)
        
        if fl == 'qo'
          qo[id] = v
        else
          qv[id] = v
        end
      end
    end
    
    # Fill the list of qualifications for all non-empty operations
    qo.each do |id, op|
      if op != 'Exists'
        quals << { :QualificationTypeId => id, :Comparator => op, :IntegerValue => qv[id].to_i } if op != ''
      else
        quals << { :QualificationTypeId => id, :Comparator => op }
      end
    end

    return quals
  end
end
