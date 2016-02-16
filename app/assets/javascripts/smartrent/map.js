var IMAGE_PATH = '/images/';
var MAP_LATITUDE = 39.078375; // Where to center map
var MAP_LONGITUDE = -76.862526;
var ZOOM_LEVEL = 10; //15 is the current useable value when limiting is turned on use 13 - 15
var ia_map;
var ia_map_markers;
var mdesc = null;
var mdesc_to = null;
var ia_map_infowindows; // added during insert of overlay
var mapStart = function() {
  // Map for Area page
  ia_map = new IAMap('map');
  ia_map.options.nav_control_type = 'none'; // Values are 'large', 'small', and 'none'; changed during insert of overlay
  ia_map.map_options = jQuery.extend({ // added during insert of overlay
    scrollwheel: true,
    draggable: true,
    disableDoubleClickZoom: false
  }, ia_map.map_options)
  ia_map.map_options.zoom = ZOOM_LEVEL; // Accepted values are 1-20;
  ia_map.params.lat = MAP_LATITUDE; // Latitude on which to center map
  ia_map.params.lon = MAP_LONGITUDE; // Longitude on which to center map
  ia_map.Markers = ia_map_markers = new IAMapMarkers();
  ia_map_infowindows = new IAMapInfoWindow(); // added during insert of overlay
  ia_map.map_options.center = new google.maps.LatLng(ia_map.params.lat, ia_map.params.lon);
  ia_map.setup();
  ia_map_markers.marker_options.map = ia_map.map;
  var marker_cntr = 0; // was 1 before adding map overlay
  var latlng = new Array();
  for (i = 0; i < categories.length; i++) {
    var ttl = categories[i];
    for (j = 0; j < pois[categories[i]].points.length; j++) {
      var curicn = IMAGE_PATH + mapIcon + '.png';
      ia_map_markers.add_marker({
        position: new google.maps.LatLng(pois[categories[i]].points[j].lat, pois[categories[i]].points[j].lon),
        title: pois[categories[i]].points[j].title,
        icon: curicn,
        visible: true
      });
      latlng.push(new google.maps.LatLng(pois[categories[i]].points[j].lat, pois[categories[i]].points[j].lon));
      if (pois[categories[i]].points[j].image_link != "") {
        ia_map_infowindows.add_infowindow('<div class="iwcontent"><span class="title"><a href="' + pois[categories[i]].points[j].image_link + '">' + pois[categories[i]].points[j].title + '</a></span><br>' + pois[categories[i]].points[j].address + '<br/><a href="' + pois[categories[i]].points[j].image_link + '">Learn More</a></div>');
      } else {
        ia_map_infowindows.add_infowindow('<div class="iwcontent"><span class="title">' + pois[categories[i]].points[j].title + '</span><br>' + pois[categories[i]].points[j].address + '<br/></div>');
      }
      var cur_marker = marker_cntr;
      google.maps.event.addListener(ia_map_markers.markers[cur_marker], 'click', function(event) {
        var current_marker = this;
        var marker_key = false;
        for (k = 0; k < ia_map_markers.markers.length; k++) {
          if (ia_map_markers.markers[k].title == current_marker.title) {
            var marker_key = k;
            break;
          }
        }
        ia_map_infowindows.close_infowindows()
        if (marker_key != false || marker_key == 0) {
          ia_map_infowindows.infowindows[marker_key].open(ia_map.map, current_marker);
        }
      });
      marker_cntr++;
    } // end inner for
  } // end outer for
  var LatLngList = latlng;
  //  Create a new viewpoint bound
  var bounds = new google.maps.LatLngBounds();
  //  Go through each...
  for (var i = 0, LtLgLen = LatLngList.length; i < LtLgLen; i++) {
    //  And increase the bounds to take this point
    bounds.extend(LatLngList[i]);
  }
  //  Fit these bounds to the map
  ia_map.map.fitBounds(bounds);
}
