// JavaScript Document
/**
 * @projectDescription Google Maps API Interace
 *
 * @author	Kevin Rice krice@merricktowle.com
 * @version	3.0
 */
/**
 * Interactive Area Map Class
 * @param map {Object}	Id of DOM object to place Google Map object in.
 */
function IAMap(map) {
  this.Directions = null;
  this.Markers = null;
  this.map_cont = document.getElementById(map);
  this.map = false;
  this.ajax_url = null;
  this.set_default = false;
  this.set_marker = false;
  this.set_property_overlay = false;
  this.property_overlay = false;
  this.options = {
    map_draggable: false,
    markers_draggable: false,
    mapController: false,
    nav_control_type: 'none',
    nav_control_position: google.maps.ControlPosition.TOP_LEFT,
    scrollwheel: false,
    scalecontrol: false,
    maptypecontrol: false,
    menumaptypecontrol: false,
    marker_clickable: true,
    display_single: true,
    display_direction_window: true
  };
  //base parameters
  this.params = {
    action: 'location_search',
    lat: 38.5,
    lon: -90,
    numResults: 100,
    mnlt: false,
    mxlt: false,
    mnln: false,
    mxln: false,
    bounds: '',
    postal_code: ''
  };
  this.map_options = {
    zoom: 13,
    center: new google.maps.LatLng(38.5, -90),
    mapTypeControl: false,
    mapTypeControlOptions: {},
    navigationControl: false,
    navigationControlOptions: {},
    scaleControl: false,
    scaleControlOptions: {},
    streetViewControl: false,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    size: new google.maps.Size(250, 250),
    styles: null
  };
}
IAMap.prototype.set_style = function(styled) {
  this.map_options.styles = styled;
}
IAMap.prototype.setup = function() {
    if (this.options.nav_control_type == 'large') {
      this.map_options.navigationControl = true;
      this.map_options.navigationControlOptions = {
        style: google.maps.NavigationControlStyle.ZOOM_PAN,
        position: this.options.nav_control_position
      }
    } else if (this.options.nav_control_type == "small") {
      this.map_options.navigationControl = true;
      this.map_options.navigationControlOptions = {
        style: google.maps.NavigationControlStyle.SMALL,
        position: this.options.nav_control_position
      }
    }
    this.map_options.scaleControl = this.options.scalecontrol;
    this.map_options.mapTypeControl = this.options.maptypecontrol;
    this.map = new google.maps.Map(this.map_cont, this.map_options);
    google.maps.event.trigger(this.map, 'resize');
  }
  /**
   * Converts address into a Google Point Object
   */
IAMap.prototype.set_default_location = function(address) {
  this.set_default = true;
  var geocoder = new google.maps.Geocoder();
  geocoder.geocode({
    'address': address
  }, this.geocode_response.bind(this));
};
/**
 * Insert Ground Overlay
 */
IAMap.prototype.add_property_overlay = function(img, lat, lon) {
  if (lat == undefined) var lat = this.params.lat;
  if (lon == undefined) var lon = this.params.lon;
  if (img == undefined) var img = this.property_overlay;
  var ne_corner = [];
  var sw_corner = [];
  ne_corner.push(lat + .0011);
  ne_corner.push(lon + .0019);
  sw_corner.push(lat - .0011);
  sw_corner.push(lon - .0019);
  var imageBounds = new google.maps.LatLngBounds(new google.maps.LatLng(sw_corner[0], sw_corner[1]), new google.maps.LatLng(ne_corner[0], ne_corner[1]));
  var property_overlay = new google.maps.GroundOverlay(img, imageBounds, {
    clickable: false,
    map: this.map
  });
};
IAMap.prototype.add_general_overlay = function(img, lat, lon) {
  if (lat == undefined) var lat = this.params.lat;
  if (lon == undefined) var lon = this.params.lon;
  if (img == undefined) var img = this.property_overlay;
  var ne_corner = [];
  var sw_corner = [];
  ne_corner.push(lat + .0006);
  ne_corner.push(lon + .0008);
  sw_corner.push(lat - .0006);
  sw_corner.push(lon - .0008);
  var imageBounds = new google.maps.LatLngBounds(new google.maps.LatLng(sw_corner[0], sw_corner[1]), new google.maps.LatLng(ne_corner[0], ne_corner[1]));
  var property_overlay = new google.maps.GroundOverlay(img, imageBounds, {
    clickable: false,
    map: this.map
  });
};
/**
 * Gets Response from Google Geocoding service. Gets and saves Latitude and Longitude
 * @param {Object} response	Response from service
 * @param {Object} Status	Geocoder Status
 * @return {Boolean}	Returns false if return geocoder fails.
 */
IAMap.prototype.geocode_response = function(response, status) {
  //validation
  if (!response || status != google.maps.GeocoderStatus.OK) {
    return false;
  } else {
    locations = response[0];
    //alert(Object.keys(locations)+"\n"+Object.values(locations));
    //set new points
    this.params.lat = locations.geometry.location.lat();
    this.params.lon = locations.geometry.location.lng();
    this.params.postal_code = locations.address_components.long_name;
    if (this.set_default) {
      this.Markers.position = this.map_options.center = new google.maps.LatLng(this.params.lat, this.params.lon);
      this.setup();
      if (this.set_marker) {
        this.Markers.position = this.map_options.center;
        this.Markers.map = this.map;
        this.Markers.marker_options.map = this.map;
        this.Markers.marker_options.position = this.Markers.position;
        this.Markers.add_marker();
      }
      if (this.set_property_overlay) {
        this.add_property_overlay(this.property_overlay, this.params.lat, this.params.lon);
      }
      this.set_default = false;
    }
  }
};
/**
 * @projectDescription Google Maps API Interace: Markers
 *
 * @author	Kevin Rice krice@merricktowle.com
 * @version	3.0
 */
/**
 * Interactive Area Map Markers Class
 * @param map {Object}	Id of DOM object to place Google Map object in.
 */
function IAMapMarkers(map, position) {
  this.map = map;
  this.position = position;
  this.markers = [];
  this.marker_options = {
    map: this.map,
    draggable: false,
    position: this.position,
    title: null,
    icon: null,
    zIndex: 1,
    flat: true
  };
}
IAMapMarkers.prototype.add_marker = function add_marker(opts) {
    this.marker_options.position = opts.position;
    this.marker_options.title = opts.title;
    if (opts.icon != null || opts.icon != undefined) this.marker_options.icon = opts.icon;
    if (opts.flat != null || opts.flat != undefined) this.marker_options.flat = opts.flat;
    if (opts.zIndex != null || opts.zIndex != undefined) this.marker_options.zIndex = opts.zIndex;
    if (opts.visible != null || opts.visible != undefined) this.marker_options.visible = opts.visible;
    if (opts.draggable != null || opts.draggable != undefined) this.marker_options.draggable = opts.draggable;
    if (opts.message != null || opts.message != undefined) {
      var marker = {
        'marker': new google.maps.Marker(this.marker_options),
        'infowindow': null
      };
      //var marker = new google.maps.Marker(this.marker_options);
      var curkey = (this.markers.length == 0) ? 0 : this.markers.length - 1;
      var curmarker = this.markers[curkey];
      var map = this.map;
      var message = opts.message;
      /*google.maps.event.addListener(marker, 'click', function() {
			var infowindow =  new google.maps.InfoWindow({
				content: message
			});

			infowindow.open(map,marker.marker);
		});*/
    } else {
      var marker = new google.maps.Marker(this.marker_options);
    }
    //if(opts.draggable != null || opts.draggable != undefined) {
    if (this.marker_options.draggable) {
      google.maps.event.addListener(marker, 'dragend', function() {
        var curpos = this.getPosition();
        if ($('#posdisplay').length > 0) var posdisplay = $('#posdisplay');
        else {
          var posdisplay = $(document.createElement('div'));
          posdisplay.attr('id', 'posdisplay');
          posdisplay.css('position', 'absolute');
          posdisplay.css('top', '0');
          posdisplay.css('left', '0');
          posdisplay.css('zIndex', '1000');
          $('body').append(posdisplay);
        }
        posdisplay.html(curpos.lat() + ',' + curpos.lng())
      });
    }
    //}
    this.markers.push(marker);
  }
  // Removes the overlays from the map, but keeps them in the array
IAMapMarkers.prototype.clear_markers = function clear_markers() {
    if (this.markers) {
      for (i in this.markers) {
        this.markers[i].setMap(null);
      }
    }
  }
  // Shows any overlays currently in the array
IAMapMarkers.prototype.show_markers = function show_markers() {
    if (this.markers) {
      for (i in this.markers) {
        this.markers[i].setMap(map);
      }
    }
  }
  // Hides any overlays currently in the array
IAMapMarkers.prototype.hide_markers = function hide_markers() {
    if (this.markers) {
      for (i in this.markers) {
        this.markers[i].setVisible(false);
      }
    }
  }
  // Hides any overlays currently in the array
IAMapMarkers.prototype.unhide_markers = function unhide_markers() {
    if (this.markers) {
      for (i in this.markers) {
        this.markers[i].setVisible(true);
      }
    }
  }
  // Deletes all markers in the array by removing references to them
IAMapMarkers.prototype.delete_markers = function delete_markers() {
  if (this.markers) {
    for (i in this.markers) {
      this.markers[i].setMap(null);
    }
    this.markers.length = 0;
  }
}

function IAMapInfoWindow() {
  this.infowindows = [];
}
IAMapInfoWindow.prototype.add_infowindow = function add_infowindow(message) {
    if (message == undefined) message = '';
    var infowindow = new google.maps.InfoWindow({
      content: message
    });
    this.infowindows.push(infowindow);
  }
  // Deletes all infowindows in the array by removing references to them
IAMapInfoWindow.prototype.delete_infowindows = function delete_infowindows() {
  if (this.infowindows) {
    this.infowindows.length = 0;
  }
}
IAMapInfoWindow.prototype.close_infowindows = function close_infowindows() {
  if (this.infowindows) {
    for (i = 0; i < this.infowindows.length; i++) {
      this.infowindows[i].close()
    }
  }
}
