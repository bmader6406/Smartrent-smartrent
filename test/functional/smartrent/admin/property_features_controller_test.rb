require 'test_helper'

module Smartrent
  class Admin::PropertyFeaturesControllerTest < ActionController::TestCase
    setup do
      @admin_property_feature = admin_property_features(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:admin_property_features)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create admin_property_feature" do
      assert_difference('Admin::PropertyFeature.count') do
        post :create, admin_property_feature: {  }
      end
  
      assert_redirected_to admin_property_feature_path(assigns(:admin_property_feature))
    end
  
    test "should show admin_property_feature" do
      get :show, id: @admin_property_feature
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @admin_property_feature
      assert_response :success
    end
  
    test "should update admin_property_feature" do
      put :update, id: @admin_property_feature, admin_property_feature: {  }
      assert_redirected_to admin_property_feature_path(assigns(:admin_property_feature))
    end
  
    test "should destroy admin_property_feature" do
      assert_difference('Admin::PropertyFeature.count', -1) do
        delete :destroy, id: @admin_property_feature
      end
  
      assert_redirected_to admin_property_features_path
    end
  end
end
