require File.dirname(__FILE__) + '/../test_helper'

class QualificationRequestTest < Test::Unit::TestCase

  # Tests converting the answer into HTML
  def test_answer_html
    r = QualificationRequest.new(
      :answer => '<QuestionFormAnswers xmlns="[theQuestionFormAnswersschemaURL]">' +
        '<Answer>' +
          '<QuestionIdentifier>ft</QuestionIdentifier>' +
          '<FreeText>SomeText</FreeText>' +
        '</Answer>' +
        '<Answer>' +
          '<QuestionIdentifier>rb</QuestionIdentifier>' +
          '<SelectionIdentifier>o1</SelectionIdentifier>' +
        '</Answer>' +
        '<Answer>' +
          '<QuestionIdentifier>ch</QuestionIdentifier>' +
          '<SelectionIdentifier>ch1</SelectionIdentifier>' +
          '<SelectionIdentifier>ch2</SelectionIdentifier>' +
          '<OtherSelectionText>os</OtherSelectionText>' +
        '</Answer>' +
        '</QuestionFormAnswers>')

    html = r.answer_html
    assert_equal '<div class="quest"><h3>Question: ft</h3><div class="res"><div class="freetext">SomeText</div></div></div>' +
      '<div class="quest"><h3>Question: rb</h3><div class="res"><div class="selection">o1</div></div></div>' +
      '<div class="quest"><h3>Question: ch</h3><div class="res"><div class="selection">ch1, ch2</div><div class="other">os</div></div></div>',
      html
  end
end
