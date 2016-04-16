require 'test_helper'

class StarterControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
  end

  test "should get configuration" do
    get :configuration
    assert_response :success
  end

end
