require File.dirname(__FILE__) + '/../test_helper'

class MturkGatewayTest < Test::Unit::TestCase
  fixtures :system_settings

  def setup
    @m = MturkGateway.new
  end

  # Tests converting raw response data to requests
  def test_data_to_requests
    qrs = [
      {:SubjectId=>"A1O6EASN5M8PVG",
       :Test=>"QuestionForm...",
       :QualificationTypeId=>"H3GZZ4C1GHCJG0ZXPJX0",
       :SubmitTime=>Time.new,
       :QualificationRequestId=>"H3GZZ4C1GHCJG0ZXPJX0FZ6ZVEZ8WZSMZJZNEZY0",
       :Answer=>"QuestionFormAnswers..."},
      {:SubjectId=>"A1O6EASN5M8PVG",
       :Test=>"QuestionForm...",
       :QualificationTypeId=>"13XZTSYADGEPQC15CBWZ",
       :SubmitTime=>Time.new,
       :QualificationRequestId=>"13XZTSYADGEPQC15CBWZZXNZT8Z35YHZM6ZCYZB0",
       :Answer=>"QuestionFormAnswers..."}]

    reqs = @m.bypass.data_to_requests(qrs)
    assert_equal 2, reqs.size
    
    reqs.each_index do |i|
      r = reqs[i]
      q = qrs[i]
      assert_equal q[:SubjectId], r.subject_id
      assert_equal q[:Test], r.test
      assert_equal q[:QualificationTypeId], r.type_id
      assert_equal q[:SubmitTime], r.submit_time
      assert_equal q[:QualificationRequestId], r.request_id
      assert_equal q[:Answer], r.answer
    end
  end

  # Tests filtering out existing (registered) requests
  def test_filter_out_existing
    # Create a request with some known id
    qrs = [
      {:SubjectId=>"A1O6EASN5M8PVG",
       :Test=>"QuestionForm...",
       :QualificationTypeId=>"H3GZZ4C1GHCJG0ZXPJX0",
       :SubmitTime=>Time.new,
       :QualificationRequestId=>"H3GZZ4C1GHCJG0ZXPJX0FZ6ZVEZ8WZSMZJZNEZY0",
       :Answer=>"QuestionFormAnswers..."},
      {:SubjectId=>"A1O6EASN5M8PVG",
       :Test=>"QuestionForm...",
       :QualificationTypeId=>"13XZTSYADGEPQC15CBWZ",
       :SubmitTime=>Time.new,
       :QualificationRequestId=>"13XZTSYADGEPQC15CBWZZXNZT8Z35YHZM6ZCYZB0",
       :Answer=>"QuestionFormAnswers..."}]

    reqs = @m.bypass.data_to_requests(qrs)
    existing = reqs[0]
    assert existing.save, "Failed to save existing request"

    q = @m.bypass.filter_out_existing(qrs)
    assert_equal 1, q.size
    assert_equal reqs[1].request_id, q[0][:QualificationRequestId]
  end

private

  # Tests converting a template into the question xml
  def test_template_to_question
    questionTemplate =
      "<% require 'cgi' %>\n" +
      "<%= CGI::escape url %>"

    blogURL = 'te st'
    
    res = @m.bypass.template_to_question(questionTemplate, blogURL)
    assert_equal res, 'te+st'
  end
  
  # Creates hits
  def test_create_hits
    blogs = ['b1', 'b2']
    hit = Hit.new(
      :title => 'Hit' + Time.now.to_i.to_s,
      :description => 'My Description',
      :rewardAmount => 0.9,
      :rewardCurrency => 'USD',
      :assignmentDurationInSeconds => 100,
      :keywords => 'test',
      :lifetimeInSeconds => 300,
      :autoApprovalDelayInSeconds => 110)
    qualifications = [
      { :QualificationTypeId => '00000000000000000000', :Comparator => 'EqualTo', :IntegerValue => '0' },
      { :QualificationTypeId => '00000000000000000070', :Comparator => 'Exists' }
    ]
    questionTemplate =
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<% require 'cgi' %>\n" +
      "<ExternalQuestion xmlns=\"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2006-07-14/ExternalQuestion.xsd\">\n" +
      "  <ExternalURL>http://www.blogbridge.com/mturk/question.htm?url=<%= CGI::escape url %></ExternalURL>\n" +
      "  <FrameHeight>500</FrameHeight>\n" +
      "</ExternalQuestion>"
    
    res = @m.create_hits(hit, blogs, qualifications, questionTemplate, 'PW2R6XYN50FZX2HP3180')
    assert_equal 0, res[:Error].size
    assert_not_nil res[:HITTypeId]
    assert_not_nil res[:Created]
    
    created, hit_type_id = res[:Created], res[:HITTypeId]
    assert_equal created.size, 2
    
    hit = created[0]
    assert_equal blogs[0], hit.blogURL
    assert_not_nil hit.hitId
    assert_equal 20, hit.hitId.length
    
    hit = created[1]
    assert_equal blogs[1], hit.blogURL
    assert_not_nil hit.hitId
    assert_equal 20, hit.hitId.length
  end

  # Creates a hit type
  def test_create_hit_type
    hit = Hit.new(
      :title => 'Test' + Time.now.to_i.to_s,
      :description => 'My Description',
      :rewardAmount => 0.9,
      :rewardCurrency => 'USD',
      :assignmentDurationInSeconds => 100,
      :keywords => 'test',
      :autoApprovalDelayInSeconds => 110)
    qualifications = [
      { :QualificationTypeId => '00000000000000000000', :Comparator => 'EqualTo', :IntegerValue => '0' },
      { :QualificationTypeId => '00000000000000000070', :Comparator => 'Exists' }
    ]
    
    # 1
    res = @m.create_hit_type(hit, qualifications)
    assert_not_nil res[:HITTypeId]
    assert_nil res[:Error]
    
    # 2
    res = @m.create_hit_type(hit, [])
    assert_not_nil res[:HITTypeId]
    assert_nil res[:Error]
  end

  # Tests creating a qualification type
  def test_create_qualification_type
    question =
      "<QuestionForm xmlns=\"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd\">" +
      "  <Question>" +
      "    <QuestionIdentifier>test_id</QuestionIdentifier>" +
      "    <DisplayName>Display Name?</DisplayName>" +
      "    <QuestionContent>" +
      "      <Text>Please take a minute to look at this url. We want you to tell us what it is primarily about. Look around it for 30 seconds and then tell us what you think:</Text>" +
      "    </QuestionContent>" +
      "    <AnswerSpecification>" +
      "      <SelectionAnswer>" +
      "        <StyleSuggestion>checkbox</StyleSuggestion>" +
      "        <Selections>" +
      "          <Selection>" +
      "            <SelectionIdentifier>unclassifiable</SelectionIdentifier>" +
      "            <Text>Unclassifiable</Text>" +
      "          </Selection>" +
      "        </Selections>" +
      "      </SelectionAnswer>" +
      "    </AnswerSpecification>" +
      "  </Question>" +
      "</QuestionForm>";
  
    # Create qualification type
    q = Qualification.new(
      :name => 'qn' + Time.now.to_i.to_s,
      :description => 'qd1',
      :keywords => 'qk1, qk11',
      :retryDelayInSeconds => 60,
      :qualificationIsActive => true,
      :testXML => question,
      :answerKeyXML => '',
      :testDurationInSeconds => 60,
      :autoGranted => false,
      :autoGrantedValue => 0)

    # Create gateway
    res = @m.create_qualificaiton_type(q)
    
    # Check the results
    assert_nil res[:Error]
    assert res[:Created]
    assert_not_nil res[:Qualification]
    
    q = res[:Qualification]
    assert_instance_of Qualification, q
    assert_not_nil q.qualificationTypeId
    assert_equal 20, q.qualificationTypeId.length
    assert_not_nil q.creationTime
    assert_instance_of Time, q.creationTime
  end
end
