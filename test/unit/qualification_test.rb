require File.dirname(__FILE__) + '/../test_helper'

class QualificationTest < Test::Unit::TestCase

  # Tests converting XML question into HTML
  def test_question_html_internal
    q = Qualification.new(:testXML => "<QuestionForm xmlns=\"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd\">" +
      "  <Question>" +
      "    <QuestionIdentifier>test_id</QuestionIdentifier>" +
      "    <DisplayName>Display Name?</DisplayName>" +
      "    <QuestionContent>" +
      "      <Text>Please take a minute to look at this url.</Text>" +
      "      <Text>We want you to tell us what it is primarily about. Look around it for 30 seconds and then tell us what you think:</Text>" +
      "    </QuestionContent>" +
      "    <AnswerSpecification>" +
      "      <SelectionAnswer>" +
      "        <StyleSuggestion>checkbox</StyleSuggestion>" +
      "        <Selections>" +
      "          <Selection>" +
      "            <SelectionIdentifier>classifiable</SelectionIdentifier>" +
      "            <Text>Classifiable</Text>" +
      "          </Selection>" +
      "          <Selection>" +
      "            <SelectionIdentifier>unclassifiable</SelectionIdentifier>" +
      "            <Text>Unclassifiable</Text>" +
      "          </Selection>" +
      "        </Selections>" +
      "      </SelectionAnswer>" +
      "      <FreeTextAnswer>" +
      "        <Constraints></Constraints>" +
      "      </FreeTextAnswer>" +
      "    </AnswerSpecification>" +
      "  </Question>" +
      "</QuestionForm>")
    
    html = q.question_html
    assert_equal "<p>Please take a minute to look at this url.</p>" +
      "<p>We want you to tell us what it is primarily about. Look around it for 30 seconds and then tell us what you think:</p>"+
      "<div>" +
      "<input type=\"checkbox\"> Classifiable<br/>" +
      "<input type=\"checkbox\"> Unclassifiable<br/>" +
      "</div>" +
      "<div>" +
      "<textarea></textarea>"+
      "</div>",
      html
  end

  # Tests converting XML question into HTML
  def test_question_html_external
    q = Qualification.new(:testXML => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<ExternalQuestion xmlns=\"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2006-07-14/ExternalQuestion.xsd\">\n" +
      "  <ExternalURL>http://www.blogbridge.com/mturk/question.htm?url=test</ExternalURL>\n" +
      "  <FrameHeight>500</FrameHeight>\n" +
      "</ExternalQuestion>")
      
    html = q.question_html
    assert_equal "<iframe src=\"http://www.blogbridge.com/mturk/question.htm?url=test\"/>", html
  end
end
