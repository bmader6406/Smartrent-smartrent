require 'test_helper'

module Smartrent
  class HomesControllerTest < ActionController::TestCase
    setup do
      @home = homes(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:homes)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create home" do
      assert_difference('Home.count') do
        post :create, home: { baths: @home.baths, beds: @home.beds, featured: @home.featured, name: @home.name, property_id: @home.property_id, sq_ft: @home.sq_ft }
      end
  
      assert_redirected_to home_path(assigns(:home))
    end
  
    test "should show home" do
      get :show, id: @home
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @home
      assert_response :success
    end
  
    test "should update home" do
      put :update, id: @home, home: { baths: @home.baths, beds: @home.beds, featured: @home.featured, name: @home.name, property_id: @home.property_id, sq_ft: @home.sq_ft }
      assert_redirected_to home_path(assigns(:home))
    end
  
    test "should destroy home" do
      assert_difference('Home.count', -1) do
        delete :destroy, id: @home
      end
  
      assert_redirected_to homes_path
    end
  end
end
