require File.dirname(__FILE__) + '/../test_helper'
require 'qualifications_controller'

# Re-raise errors caught by the controller.
class QualificationsController; def rescue_action(e) raise e end; end

class QualificationsControllerTest < Test::Unit::TestCase
  def setup
    @controller = QualificationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
