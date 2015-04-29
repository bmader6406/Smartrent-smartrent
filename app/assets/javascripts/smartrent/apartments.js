// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var pois = {};
var categories = [];
var cat_counter = 1;
var mapIcon = "homeIcon"
$(function(){
  $('.apartment_listing input, .apartment_listing select').change(function(){
    $('.apartment_listing').submit();
  });
  $(".search-apartment-item").click(function(){
    if (this.id == 'listResults' && $(this).hasClass('listOff')) {
      $(this).removeClass('listOff').addClass('listOn')
      $(this).siblings().removeClass('mapOn').addClass('mapOff')
      $('.map-results').hide(function(){
        $('.listing-results').show();
      });
    }
    else if (this.id == 'mapResults' && $(this).hasClass('mapOff')) {
      $(this).removeClass('mapOff').addClass('mapOn')
      $(this).siblings().removeClass('listOn').addClass('listOff')
      $('.listing-results').hide(function(){
        $('.map-results').show();
        var map_results_html = $('.map-results').html();
        map_results_html = map_results_html.replace(/\n/g, "").replace(/ /g, "")
        if (map_results_html == '')
        {
          apartments_path = Routes.smartrent_apartments_path({format: "json"}) + location.search
          $.get(apartments_path, function(data){
            apartments = data;
            pois['all'] = {'show':true,'points':[]};
            for(var x in apartments) {
              var apartment = apartments[x]
              pois['all']['points'].push({
                  title: apartment.title,
                  description: apartment.short_description,
                  address: apartment.address + ',' + apartment.city + ',' + apartment.state,
                  lat: apartment.lat,
                  lon: apartment.lng,
                  image: apartment.image,
                  image_link: apartment.image
              });
            }
            mapStart();
          });
        }
      });

    }
  })
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
