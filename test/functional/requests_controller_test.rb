require File.dirname(__FILE__) + '/../test_helper'
require 'requests_controller'

# Re-raise errors caught by the controller.
class RequestsController; def rescue_action(e) raise e end; end

class RequestsControllerTest < Test::Unit::TestCase
  def setup
    @controller = RequestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def teardown
    QualificationRequest.delete_all
  end

  # Replace this with your real tests.
  def test_showing_requests
    # Nothing showed
    get :index
    requests = assigns(:requests)
    assert_response :success
    assert_template "requests/index"
    assert_not_nil requests
    assert_equal 0, requests.size
    
    # Add new qualification requests to the database (not reviewed, approved, and rejected)
    qn = qual_non_reviewed
    qa = QualificationRequest.new(:request_id => 'ra', :type_id => 't', :subject_id => 's', :test => 't', :answer => 'a', :submit_time => Time.now, :approved => true)
    qr = QualificationRequest.new(:request_id => 'rr', :type_id => 't', :subject_id => 's', :test => 't', :answer => 'a', :submit_time => Time.now, :approved => false)
    assert qn.save
    assert qa.save
    assert qr.save

    # Make sure only not approved is returned
    get :index
    requests = assigns(:requests)
    assert_response :success
    assert_template "requests/index"
    assert_not_nil requests
    assert_equal 1, requests.size
    assert_equal 'rn', requests[0].request_id
  end
  
  # Tests updating from AWS
  def test_updating_from_aws
    get :update_from_aws
    assert_response :success
    assert_nil assigns(:error)
    assert_template 'requests/successful_update'
  end
  
  # Tests loading the request examination page
  def test_examine_request
    qn = qual_non_reviewed
    assert qn.save
    
    get :examine, :id => qn.id
    assert_response :success
    assert_not_nil assigns(:request)
    assert_template 'requests/examine'
  end

  # Tests exmining non-existing request
  def test_exemine_request_not_exists
    get :examine, :id => -1
    assert_response :redirect
    assert_redirected_to :controller => 'requests', :action => 'index'
  end

  # Tests how approving works
  def test_approve_request
    qn = qual_non_reviewed
    assert qn.save
    
    get :approve, :id => qn.id
    assert_response :redirect
    assert_redirected_to :controller => 'requests', :action => 'index'
    
    q = QualificationRequest.find(qn.id)
    assert q.approved
  end

  # Tests approving non-existing request
  def test_approve_request_not_exists
    get :approve, :id => -1
    assert_response :redirect
    assert_redirected_to :controller => 'requests', :action => 'index'
  end

  # Tests rejecting non-existing request
  def test_reject_request_not_exists
    get :reject, :id => -1
    assert_response :redirect
    assert_redirected_to :controller => 'requests', :action => 'index'
  end
  
  # Tests how rejection works
  def test_reject_request
    qn = qual_non_reviewed
    assert qn.save
    
    get :reject, :id => qn.id
    assert_response :redirect
    assert_redirected_to :controller => 'requests', :action => 'index'
    
    q = QualificationRequest.find(qn.id)
    assert !q.approved
  end

private

  # Returns non-reviewed qualification
  def qual_non_reviewed
    QualificationRequest.new(:request_id => 'rn', :type_id => 't', :subject_id => 's', :test => 't', :answer => 'a', :submit_time => Time.now)
  end
end
