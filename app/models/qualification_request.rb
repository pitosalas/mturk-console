require 'rexml/document'

class QualificationRequest < ActiveRecord::Base
  include REXML

  validates_presence_of :request_id,
                        :type_id,
                        :subject_id,
                        :test,
                        :answer,
                        :submit_time

  # Returns the list of non-reviewed qualification requests
  def self.find_non_reviewed
    find(:all, :conditions => 'approved IS NULL', :order => 'submit_time DESC')
  end
  
  # Converts test XML into HTML
  def question_html
    Qualification.question_html_ext(test)
  end
  
  # Converts the answer XML into HTML
  def answer_html
    return '' if answer.nil? || answer.strip.empty?
    
    doc = Document.new(answer)
    question_form_answers = doc.root
    
    html = ''
    question_form_answers.each_element { |answer| html += as_answer(answer) }
    return html
  end

private

  # Parses the answer section, groups the elements and converts it into HTML
  def as_answer(answer)
    html = '<div class="quest">'
    
    # The name of the group
    html += "<h3>Question: #{answer.elements['QuestionIdentifier'].text}</h3>"
    
    # The results
    html += '<div class="res">'
    
    # - Selections
    sel = []
    answer.each_element('SelectionIdentifier') { |el| sel << el.text }
    html += "<div class=\"selection\">#{sel.join(', ')}</div>" if sel.size > 0
    
    # - Free text
    answer.each_element('FreeText') { |el| html += "<div class=\"freetext\">#{el.text}</div>" }
    
    # - Other text
    answer.each_element('OtherSelectionText') { |el| html += "<div class=\"other\">#{el.text}</div>" }

    html += '</div>'
    
    return html + '</div>'
  end
end
