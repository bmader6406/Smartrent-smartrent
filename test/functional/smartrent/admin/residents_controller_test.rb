require 'test_helper'

module Smartrent
  class Admin::ResidentsControllerTest < ActionController::TestCase
    setup do
      @admin_resident = admin_residents(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:admin_residents)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create admin_resident" do
      assert_difference('Admin::Resident.count') do
        post :create, admin_resident: {  }
      end
  
      assert_redirected_to admin_resident_path(assigns(:admin_resident))
    end
  
    test "should show admin_resident" do
      get :show, id: @admin_resident
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @admin_resident
      assert_response :success
    end
  
    test "should update admin_resident" do
      put :update, id: @admin_resident, admin_resident: {  }
      assert_redirected_to admin_resident_path(assigns(:admin_resident))
    end
  
    test "should destroy admin_resident" do
      assert_difference('Admin::Resident.count', -1) do
        delete :destroy, id: @admin_resident
      end
  
      assert_redirected_to admin_residents_path
    end
  end
end
