require 'test_helper'

module Smartrent
  class Admin::FeaturesControllerTest < ActionController::TestCase
    setup do
      @admin_feature = admin_features(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:admin_features)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create admin_feature" do
      assert_difference('Admin::Feature.count') do
        post :create, admin_feature: {  }
      end
  
      assert_redirected_to admin_feature_path(assigns(:admin_feature))
    end
  
    test "should show admin_feature" do
      get :show, id: @admin_feature
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @admin_feature
      assert_response :success
    end
  
    test "should update admin_feature" do
      put :update, id: @admin_feature, admin_feature: {  }
      assert_redirected_to admin_feature_path(assigns(:admin_feature))
    end
  
    test "should destroy admin_feature" do
      assert_difference('Admin::Feature.count', -1) do
        delete :destroy, id: @admin_feature
      end
  
      assert_redirected_to admin_features_path
    end
  end
end
