// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var pois = {};
var categories = [];
var cat_counter = 1;
var mapIcon = "homeIcon"
$(function(){
  $('.property_listing input, .property_listing select').change(function(){
    $.blockUI();
    $('.property_listing').submit();
  });
  $(".search-property-item").click(function(){
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
          Property.loadMap();
        }
      });

    }
  })
});

Property = {
  cities: function(state, city){
    $('#q_state_eq').val(state)
    $('#q_city_eq').val(city)
    $('.property_listing').submit();
  },
  counties: function(state, county){
    $('#q_state_eq').val(state)
    $('#q_county_eq').val(county)
    $('.property_listing').submit();
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
  loadMap: function() {
    properties_path = Routes.smartrent_properties_path({format: "json"}) + location.search
    $.get(properties_path, function(data){
      properties = data;
      pois['all'] = {'show':true,'points':[]};
      for(var x in properties) {
        var property = properties[x]
        pois['all']['points'].push({
            title: property.title,
            description: property.short_description,
            address: property.address + ',' + property.city + ',' + property.state,
            lat: property.lat,
            lon: property.lng,
            image: property.image,
            image_link: property.image
        });
      }
      mapStart();
    });
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
