require File.dirname(__FILE__) + '/../test_helper'
require 'hits_controller'

# Re-raise errors caught by the controller.
class HitsController; def rescue_action(e) raise e end; end

class HitsControllerTest < Test::Unit::TestCase
  def setup
    @controller = HitsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # No parameters
  def test_params_to_qualifications_empty
    p = {}
    q = @controller.bypass.params_to_qualifications(p)
    assert_equal q.length, 0
  end

  # No qualifications selected
  def test_params_to_qualifications_nothing
    p = { 'qo_01234567890123456789' => '', 'qv_01234567890123456789' => '' }
    q = @controller.bypass.params_to_qualifications(p)
    assert_equal q.length, 0
  end

  # No qualifications selected, but a value entered
  def test_params_to_qualifications_nothing_2
    p = { 'qo_01234567890123456789' => '', 'qv_01234567890123456789' => '2' }
    q = @controller.bypass.params_to_qualifications(p)
    assert_equal q.length, 0
  end

  # A qualification is selected
  def test_params_to_qualifications
    p = { 'qo_01234567890123456789' => '1', 'qv_01234567890123456789' => '2' }
    q = @controller.bypass.params_to_qualifications(p)
    assert_equal q.length, 1
    assert_equal q[0][:id], '01234567890123456789'
    assert_equal q[0][:operation], '1'
    assert_equal q[0][:value], '2'
  end
  
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
