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
  },
  toggleCities: function(state) {
    state = state.replace(" ", "_")
    if ($('#citiesList' + state).css('display') == 'none')
    {
      $('#citiesList' + state).slideDown("slow", function(){
        $('#citiesPlusMinus' + state).html("-");
      });
    }
    else
    {
      $('#citiesList' + state).slideUp("slow", function(){
        $('#citiesPlusMinus' + state).html("+");
      });
    }
  },
  toggleCounties: function(state) {
    state = state.replace(" ", "_")
    if ($('#countiesList' + state).css('display') == 'none')
    {
      $('#countiesList' + state).slideDown("slow", function(){
        $('#countiesPlusMinus' + state).html("-");
      });
    }
    else
    {
      $('#countiesList' + state).slideUp("slow", function(){
        $('#countiesPlusMinus' + state).html("+");
      });
    }
  },
  showState: function(state) {
    state = state.replace(" ", "_")
    var id = '#results-'+state
    if ($(id).css('display') == 'none')
    {
      $(id).slideDown("fast", function(){
        $(this).removeClass('hidden')
        $('#plusMinus' + state).html("-");
        $('#counties' + state).slideDown("fast")
        $('#cities' + state).slideDown("fast")
      });
    }
    else
    {
      $(id).slideUp("fast", function(){
        $('#counties' + state).slideUp("fast")
        $('#cities' + state).slideUp("fast")
        $('#plusMinus' + state).html("+");
      });
    }
  }


}
