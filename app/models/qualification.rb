require 'rexml/document'

class Qualification < ActiveRecord::Base
  include REXML

  validates_presence_of     :name, 
                            :description,
                            :testDurationInSeconds

  validates_length_of       :description, :maximum => 2000
  validates_length_of       :keywords, :maximum => 1000, :allow_nil => true
  
  validates_numericality_of :autoGrantedValue, :allow_nil => true, :only_integer => true
  validates_numericality_of :retryDelayInSeconds, :allow_nil => true, :only_integer => true
  validates_numericality_of :testDurationInSeconds, :only_integer => true

  def self.question_html_ext(testXML)
    return '' if (testXML.nil? || testXML.strip.empty?)
    
    doc = Document.new(testXML)
    root = doc.root
    
    if root.name == 'ExternalQuestion'
      return question_html_external(root)
    else
      return question_html_internal(root)
    end
  end

  # Converts the question XML (testXML) into the HTML for brief preview
  def question_html
    Qualification.question_html_ext(testXML)
  end

protected
  
  def validate
    errors.add(:retryDelayInSeconds, "should be non-negative.") unless retryDelayInSeconds.nil? || retryDelayInSeconds >= 0
    errors.add(:testDurationInSeconds, "should be positive.") unless !testDurationInSeconds.nil? && testDurationInSeconds > 0
  end

private

  # Parses external question definition and outputs HTML
  def self.question_html_external(root)
    url = root.elements['ExternalURL'].text
    return "<iframe src=\"#{url}\"/>"
  end

  # Parses inline definition of the question form and outputs HTML
  def self.question_html_internal(question_form)
    html = ''
    
    # Question content
    question = question_form.elements['Question']
    question_content = question.elements['QuestionContent']
    question_content.each_element do |el|
      html += "<p>#{el.text}</p>" if el.name == 'Text'
    end
    
    # Answer Specification
    answer_specification = question.elements['AnswerSpecification']
    answer_specification.each_element do |el|
      if el.name == 'SelectionAnswer'
        html += as_selection_answer(el)
      elsif el.name == 'FreeTextAnswer'
        html += '<div><textarea></textarea></div>'
      end
    end
    
    return html
  end
  
  # Parses SelectionAnswer section
  def self.as_selection_answer(selection_answer)
    html = '<div>'
    
    style_suggestion = selection_answer.elements['StyleSuggestion'].text
    selections = selection_answer.elements['Selections']
    
    case style_suggestion
      when 'checkbox', 'radiobutton':
        selections.each_element do |selection|
          text = selection.elements['Text'].text
          case style_suggestion
            when 'checkbox':    html += "<input type=\"checkbox\"> #{text}<br/>"
            when 'radiobutton': html += "<input type=\"radio\"> #{text}<br/>"
          end
        end

      when 'dropdown', 'list', 'multichooser':
        html += '<select' +
          (style_suggestion == 'list' || style_suggestion == 'multichooser' ? ' size="5" ' : '') +
          (style_suggestion == 'multichooser' ? ' multiple' : '') + '>'
        selections.each_element do |selection|
          text = selection.elements['Text'].text
          html += "<option>#{text}</option>"
        end
        html += '</select>'

    end   
      
    return html += '</div>'
  end
  
  def self.as_style_to_type(style)
    case style
      when 'checkbox': 'checkbox'
      when 'radiobutton': 'radio'
    end
  end
end