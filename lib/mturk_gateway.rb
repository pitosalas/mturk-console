require 'ruby-aws'
require 'erb'

# MTurk gateway to talk to real MTurk
class MturkGateway
  # MTurk connection
  @mturk = nil
  # True / False if sandbox/production, nil if not initialized
  @sandbox = nil

  # Approves / rejects the qualification request
  def approve_qualification_request(req, approve)
    mt = get_mturk
    error = nil

    begin
      if approve
        mt.GrantQualification(
          :Operation => 'GrantQualification',
          :QualificationRequestId => req.request_id)
      else
        mt.RejectQualificationRequest(
          :Operation => 'RejectQualificationRequest',
          :QualificationRequestId => req.request_id)
      end
    rescue => e
      error = e.message
    end
      
    return :Error => error
  end
  
  # Contacts MTurk and creates qualification type
  def create_qualificaiton_type(q)
    mt = get_mturk
    created = false
    error = nil
    begin
      res = mt.CreateQualificationType(
          :Operation => 'CreateQualificationType',
          :Name => q.name,
          :Description => q.description,
          :QualificationTypeStatus => q.qualificationIsActive ? 'Active' : 'Inactive',
          :Test => q.testXML,
          :TestDurationInSeconds => q.testDurationInSeconds,
          :Keywords => q.keywords,
          :RetryDelayInSeconds => q.retryDelayInSeconds,
          :AnswerKey => q.answerKeyXML.strip.empty? ? nil : q.answerKeyXML,
          :AutoGranted => q.autoGranted,
          :AutoGrantedValue => q.autoGranted ? q.autoGrantedValue : nil)

      created = true
      
      # Update qualification object with ID and creation time
      qt = res[:QualificationType]
      q.qualificationTypeId = qt[:QualificationTypeId]
      q.creationTime = qt[:CreationTime]
    rescue => e
      error = e.message
    end
    
    return :Created => created, :Error => error, :Qualification => q
  end
  
  # Creates HITs for given list of blogs using the template and qualifications
  # Returns initialized Hit objects ready for saving
  def create_hits(hit_template, blogs, qualifications, questionTemplate = SystemSetting[:ExternalQuestionXML].to_s, hit_type_id = nil)
    created = []
    error = []

    begin
      if hit_type_id == nil
        res = create_hit_type(hit_template, qualifications)
        hit_type_id = res[:HITTypeId]
      end
      
      if hit_type_id != nil
        # Hit type is created
        
        mt = get_mturk
        tmpl = ERB.new(questionTemplate)
        
        blogs.each do |url|

          questionXML = template_to_question(questionTemplate, url)
          
          res = mt.CreateHIT(
            :Operation      => 'CreateHIT',
            :HITTypeId      => hit_type_id,
            :Question       => questionXML,
            :LifetimeInSeconds  => hit_template.lifetimeInSeconds,
            :MaxAssignments     => hit_template.maxAssignments)
          
          hit = hit_template.clone
          hit.blogURL = url
          hit.hitId = res[:HIT][:HITId]
          hit.typeId = hit_type_id
          hit.sandbox = @sandbox
          
          created << hit
        end
      else
        error << res[:Error]
      end
    rescue => e
      error << e.message
    end

    return :Created => created, :Error => error, :HITTypeId => hit_type_id
  end
  
  # Creates a hit type and returns the ID or error message
  def create_hit_type(hit, qualifications)
    mt = get_mturk
    error = nil
    type_id = nil
    
    begin
      res = mt.RegisterHITType(
        :Operation                    => 'RegisterHITType',
        :Title                        => hit.title,
        :Description                  => hit.description,
        :Reward                       => { :Amount => hit.rewardAmount, :CurrencyCode => hit.rewardCurrency},
        :AssignmentDurationInSeconds  => hit.assignmentDurationInSeconds,
        :Keywords                     => hit.keywords,
        :AutoApprovalDelayInSeconds   => hit.autoApprovalDelayInSeconds,
        :QualificationRequirement     => (qualifications == nil || qualifications.size == 0) ? nil : qualifications)
      type_id = res[:RegisterHITTypeResult][:HITTypeId]
    rescue => e
      error = e.message
    end
    
    return :HITTypeId => type_id, :Error => error
  end
  
  # Returns new qualification requests.
  # (array of QualificationRequest objects)
  def get_new_qualification_requests
    mt = get_mturk
    error = nil
    reqs = nil
    
    begin
      res = mt.GetQualificationRequests(:Operation => 'GetQualificationRequests')
      
      # Convert results into request objects
      rr = res[:GetQualificationRequestsResult]
      return [] if rr[:NumResults] == 0
      qrs = rr[:QualificationRequest]
      
      # Convert a single qualification request to an array for convenience
      qrs = [ qrs ] if !qrs.kind_of?(Array)
      
      # Remove all requests that are registered yet
      qrs = filter_out_existing(qrs)
    
      # Create the list of qualification objects from the rest
      reqs = data_to_requests(qrs)
    rescue => e
      error = e.message
    end
    
    return :Requests => reqs, :Error => error
  end
  
  private

  # Removes the response data records that are already registered in the database
  def filter_out_existing(qrs)
    qrs = qrs.delete_if do |q|
      QualificationRequest.exists?(:request_id => q[:QualificationRequestId])
    end
  end

  # Converts the response data to requests list
  def data_to_requests(qrs)
    reqs = []
    qrs.each do |qr|
      # Make an attempt to find
      reqs << QualificationRequest.new(
        :subject_id => qr[:SubjectId],
        :test => qr[:Test],
        :type_id => qr[:QualificationTypeId],
        :submit_time => qr[:SubmitTime],
        :request_id => qr[:QualificationRequestId],
        :answer => qr[:Answer])
    end
    return reqs
  end

  # Returns MTurk connection for this request
  def get_mturk
    if @mturk.nil?
      host = SystemSetting[:Host].to_s
      @mturk = Amazon::WebServices::MechanicalTurkRequester.new(
        :Host => host,
        :AWSAccessKeyId => SystemSetting[:AWSAccessKeyId].to_s,
        :AWSAccessKey => SystemSetting[:AWSAccessKey].to_s)

      @sandbox = (host =~ /sandbox/i) != nil
    end
    
    return @mturk
  end
  
  # Converts a template into a question XML using the blog URL given
  def template_to_question(template, blogURL)
    erb = ERB.new(template, 0, "%<>")
    url = blogURL
    res = erb.result binding
    
    return res
  end
  
  def logger
    @logger = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log") if @logger == nil
    return @logger
  end
end