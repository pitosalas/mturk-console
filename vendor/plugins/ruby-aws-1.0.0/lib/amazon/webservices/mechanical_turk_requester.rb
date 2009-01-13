# Copyright:: Copyright (c) 2007 Amazon Technologies, Inc.
# License::   Apache License, Version 2.0

require 'erb'
require 'amazon/util'
require 'amazon/webservices/util/xml_simplifier'
require 'amazon/webservices/util/convenience_wrapper'
require 'amazon/webservices/mechanical_turk'

module Amazon
module WebServices

class MechanicalTurkRequester < Amazon::WebServices::Util::ConvenienceWrapper

  WSDL_VERSION = "2007-03-12"

  ABANDONMENT_RATE_QUALIFICATION_TYPE_ID = "00000000000000000070";
  APPROVAL_RATE_QUALIFICATION_TYPE_ID = "000000000000000000L0";
  REJECTION_RATE_QUALIFICATION_TYPE_ID = "000000000000000000S0";
  RETURN_RATE_QUALIFICATION_TYPE_ID = "000000000000000000E0";
  SUBMISSION_RATE_QUALIFICATION_TYPE_ID = "00000000000000000000";
  LOCALE_QUALIFICATION_TYPE_ID = "00000000000000000071";

  serviceCall :RegisterHITType, :RegisterHITTypeResult, { :MaxAssignments => 1,
                                                          :AssignmentDurationInSeconds => 60*60,
                                                          :AutoApprovalDelayInSeconds => 60*60*24*7
                                                        }

  serviceCall :CreateHIT, :HIT, { :MaxAssignments => 1,
                                  :AssignmentDurationInSeconds => 60*60,
                                  :AutoApprovalDelayInSeconds => 60*60*24*7,
                                  :LifetimeInSeconds => 60*60*24,
                                  :ResponseGroup => %w( Minimal HITDetail HITQuestion )
                                }

  serviceCall :DisableHIT, :DisableHITResult
  serviceCall :DisposeHIT, :DisposeHITResult
  serviceCall :ExtendHIT, :ExtendHITResult
  serviceCall :ForceExpireHIT, :ForceExpireHITResult
  serviceCall :GetHIT, :HIT, { :ResponseGroup => %w( Minimal HITDetail HITQuestion HITAssignmentSummary ) }
  
  serviceCall :SearchHITs, :SearchHITsResult
  serviceCall :GetReviewableHITs, :GetReviewableHITsResult
  serviceCall :SetHITAsReviewing, :SetHITAsReviewingResult
  serviceCall :GetAssignmentsForHIT, :GetAssignmentsForHITResult
  serviceCall :ApproveAssignment, :ApproveAssignmentResult
  serviceCall :RejectAssignment, :RejectAssignmentResult

  paginate :SearchHITs, :HIT
  paginate :GetReviewableHITs, :HIT
  paginate :GetAssignmentsForHIT, :Assignment
  
  serviceCall :GrantBonus, :GrantBonusResult
  serviceCall :GetBonusPayments, :GetBonusPaymentsResult

  serviceCall :CreateQualificationType, :QualificationType, { :QualificationTypeStatus => 'Active' }
  serviceCall :GetQualificationType, :QualificationType
  serviceCall :SearchQualificationTypes, :SearchQualificationTypesResult, { :MustBeRequestable => true }
  serviceCall :UpdateQualificationType, :QualificationType
  serviceCall :GetQualificationsForQualificationType, :GetQualificationsForQualificationTypeResult, { :Status => 'Granted' }
  serviceCall :GetHITsForQualificationType, :GetHITsForQualificationTypeResult

  paginate :SearchQualificationTypes, :QualificationType
  paginate :GetQualificationsForQualificationType, :Qualification

  serviceCall :AssignQualification, :AssignQualificationResult
  serviceCall :GetQualificationRequests, :GetQualificationRequestsResult
  serviceCall :GrantQualification, :GrantQualificationResult
  serviceCall :RejectQualificationRequest, :RejectQualificationRequestResult
  serviceCall :GetQualificationScore, :Qualification
  serviceCall :UpdateQualificationScore, :UpdateQualificationScoreResult
  serviceCall :RevokeQualification, :RevokeQualificationResult

  paginate :GetQualificationRequests, :QualificationRequest

  serviceCall :SetHITTypeNotification, :SetHITTypeNotificationResult
  serviceCall :SetWorkerAcceptLimit, :SetWorkerAcceptLimitResult
  serviceCall :GetWorkerAcceptLimit, :GetWorkerAcceptLimitResult

  serviceCall :GetFileUploadURL, :GetFileUploadURLResult
  serviceCall :GetAccountBalance, :GetAccountBalanceResult
  serviceCall :GetRequesterStatistic, :GetStatisticResult, { :Count => 1 }

  serviceCall :NotifyWorkers, :NotifyWorkersResult

  def initialize(args={})
    newargs = args.dup
    unless args[:Config].nil?
      loaded = Amazon::Util::DataReader.load( args[:Config], :YAML )
      newargs = args.merge loaded.inject({}) {|a,b| a[b[0].to_sym] = b[1] ; a }
    end
    raise "Cannot override WSDL version ( #{WSDL_VERSION} )" unless args[:Version].nil? or args[:Version].equals? WSDL_VERSION
    super newargs.merge( :Name => :AWSMechanicalTurkRequester, 
                         :ServiceClass => Amazon::WebServices::MechanicalTurk,
                         :Version => WSDL_VERSION )
  end
  
  # Create a series of similar hits, sharing common parameters.  Utilizes HitType
  # * hit_template is the array of parameters to pass to createHIT.
  # * question_template will be passed as a template into ERB to generate the :Question parameter
  # * the RequesterAnnotation parameter of hit_template will also be passed through ERB
  # * hit_data_set should consist of an array of hashes defining unique instance variables utilized by question_template
  def createHITs( hit_template, question_template, hit_data_set)
    hit_template = hit_template.dup
    lifetime = hit_template[:LifetimeInSeconds]
    annotation_template = hit_template[:RequesterAnnotation]
    hit_template.delete :LifetimeInSeconds
    hit_template.delete :RequesterAnnotation
    
    ht = registerHITType( hit_template )[:HITTypeId]
  
    created = []
    failed = []
    hit_data_set.each { |hit_data|
      begin
        b = Amazon::Util::Binder.new( hit_data )
        annotation = b.erb_eval( annotation_template )
        question = b.erb_eval( question_template )
        created << self.createHIT( :HITTypeId => ht, 
                                   :LifetimeInSeconds => lifetime, 
                                   :Question => question, 
                                   :RequesterAnnotation => ( hit_data[:RequesterAnnotation] || annotation || "") 
                                 )
      rescue => e
        failed << hit_data.merge( :Error => e.message )
      end
    }
    return :Created => created, :Failed => failed
  end
  
  def getHITResults(list)
    results = []
    list.each do |h|
      hit = getHIT( :HITId => h[:HITId] )
      getAssignmentsForHITAll( :HITId => h[:HITId] ).each {|assignment|
        results << ( hit.merge( assignment ) )
      }
    end
    results.flatten
  end
  
  # Returns available funds in USD
  # Calls getAccountBalance and parses out the correct amount
  def availableFunds
    return getAccountBalance[:AvailableBalance][:Amount]
  end

  # helper function to simplify answer XML
  def simplifyAnswer( answerXML )
    answerHash = Amazon::WebServices::Util::XMLSimplifier.simplify REXML::Document.new(answerXML)
    list = [answerHash[:Answer]].flatten
    list.inject({}) { |list, answer|
      id = answer[:QuestionIdentifier]
      result = answer[:FreeText] || answer[:SelectionIdentifier] || answer[:UploadedFileKey]
      list[id] = result
      list
    }
  end

end # MechanicalTurkRequester

end # Amazon::WebServices
end # Amazon
