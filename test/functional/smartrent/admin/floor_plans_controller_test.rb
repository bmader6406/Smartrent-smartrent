require 'test_helper'

module Smartrent
  class Admin::FloorPlansControllerTest < ActionController::TestCase
    setup do
      @admin_floor_plan = admin_floor_plans(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:admin_floor_plans)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create admin_floor_plan" do
      assert_difference('Admin::FloorPlan.count') do
        post :create, admin_floor_plan: { baths: @admin_floor_plan.baths, beds: @admin_floor_plan.beds, name: @admin_floor_plan.name, origin_id: @admin_floor_plan.origin_id, penthouse: @admin_floor_plan.penthouse, property_id: @admin_floor_plan.property_id, rent_max: @admin_floor_plan.rent_max, rent_min: @admin_floor_plan.rent_min, sq_feet_max: @admin_floor_plan.sq_feet_max, sq_feet_min: @admin_floor_plan.sq_feet_min, url: @admin_floor_plan.url }
      end
  
      assert_redirected_to admin_floor_plan_path(assigns(:admin_floor_plan))
    end
  
    test "should show admin_floor_plan" do
      get :show, id: @admin_floor_plan
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @admin_floor_plan
      assert_response :success
    end
  
    test "should update admin_floor_plan" do
      put :update, id: @admin_floor_plan, admin_floor_plan: { baths: @admin_floor_plan.baths, beds: @admin_floor_plan.beds, name: @admin_floor_plan.name, origin_id: @admin_floor_plan.origin_id, penthouse: @admin_floor_plan.penthouse, property_id: @admin_floor_plan.property_id, rent_max: @admin_floor_plan.rent_max, rent_min: @admin_floor_plan.rent_min, sq_feet_max: @admin_floor_plan.sq_feet_max, sq_feet_min: @admin_floor_plan.sq_feet_min, url: @admin_floor_plan.url }
      assert_redirected_to admin_floor_plan_path(assigns(:admin_floor_plan))
    end
  
    test "should destroy admin_floor_plan" do
      assert_difference('Admin::FloorPlan.count', -1) do
        delete :destroy, id: @admin_floor_plan
      end
  
      assert_redirected_to admin_floor_plans_path
    end
  end
end
