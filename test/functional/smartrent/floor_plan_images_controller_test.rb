require 'test_helper'

module Smartrent
  class FloorPlanImagesControllerTest < ActionController::TestCase
    setup do
      @floor_plan_image = floor_plan_images(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:floor_plan_images)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create floor_plan_image" do
      assert_difference('FloorPlanImage.count') do
        post :create, floor_plan_image: { caption: @floor_plan_image.caption, home_id: @floor_plan_image.home_id, image: @floor_plan_image.image }
      end
  
      assert_redirected_to floor_plan_image_path(assigns(:floor_plan_image))
    end
  
    test "should show floor_plan_image" do
      get :show, id: @floor_plan_image
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @floor_plan_image
      assert_response :success
    end
  
    test "should update floor_plan_image" do
      put :update, id: @floor_plan_image, floor_plan_image: { caption: @floor_plan_image.caption, home_id: @floor_plan_image.home_id, image: @floor_plan_image.image }
      assert_redirected_to floor_plan_image_path(assigns(:floor_plan_image))
    end
  
    test "should destroy floor_plan_image" do
      assert_difference('FloorPlanImage.count', -1) do
        delete :destroy, id: @floor_plan_image
      end
  
      assert_redirected_to floor_plan_images_path
    end
  end
end
