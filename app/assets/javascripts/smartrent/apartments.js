// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function(){
  $('.apartment_listing input, .apartment_listing select').change(function(){
    $('.apartment_listing').submit();
  });
});

Apartment = {
  cities: function(state, city){
    $('#q_state_eq').val(state)
    $('#q_city_eq').val(city)
    $('.apartment_listing').submit();
  },
  counties: function(state, county){
    $('#q_state_eq').val(state)
    $('#q_county_eq').val(county)
    $('.apartment_listing').submit();
  }
}
