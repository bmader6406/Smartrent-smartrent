require 'test_helper'

module Smartrent
  class ApartmentsControllerTest < ActionController::TestCase
    setup do
      @apartment = apartments(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:apartments)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create apartment" do
      assert_difference('Apartment.count') do
        post :create, apartment: { address: @apartment.address, city: @apartment.city, county: @apartment.county, detail_url: @apartment.detail_url, four_bedroom_price: @apartment.four_bedroom_price, lat: @apartment.lat, lng: @apartment.lng, one_bedroom_price: @apartment.one_bedroom_price, pent_house_price: @apartment.pent_house_price, phone_number: @apartment.phone_number, short_description: @apartment.short_description, special_promotion: @apartment.special_promotion, state: @apartment.state, studio_price: @apartment.studio_price, three_bedroom_price: @apartment.three_bedroom_price, title: @apartment.title, two_bedroom_price: @apartment.two_bedroom_price }
      end
  
      assert_redirected_to apartment_path(assigns(:apartment))
    end
  
    test "should show apartment" do
      get :show, id: @apartment
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @apartment
      assert_response :success
    end
  
    test "should update apartment" do
      put :update, id: @apartment, apartment: { address: @apartment.address, city: @apartment.city, county: @apartment.county, detail_url: @apartment.detail_url, four_bedroom_price: @apartment.four_bedroom_price, lat: @apartment.lat, lng: @apartment.lng, one_bedroom_price: @apartment.one_bedroom_price, pent_house_price: @apartment.pent_house_price, phone_number: @apartment.phone_number, short_description: @apartment.short_description, special_promotion: @apartment.special_promotion, state: @apartment.state, studio_price: @apartment.studio_price, three_bedroom_price: @apartment.three_bedroom_price, title: @apartment.title, two_bedroom_price: @apartment.two_bedroom_price }
      assert_redirected_to apartment_path(assigns(:apartment))
    end
  
    test "should destroy apartment" do
      assert_difference('Apartment.count', -1) do
        delete :destroy, id: @apartment
      end
  
      assert_redirected_to apartments_path
    end
  end
end
