//= ma
var draggable_map = window.location.href.match(/(new|edit)/);

var map = new google.maps.Map(document.getElementById('google-map'));
var marker = new google.maps.Marker();
ck_lat = /^(-?[1-8]?\d(?:\.\d{1,18})?|90(?:\.0{1,18})?)$/;
ck_lon = /^(-?(?:1[0-7]|[1-9])?\d(?:\.\d{1,18})?|180(?:\.0{1,18})?)$/;

// Update the map with the given coordinates - View Config Page
if($('#loc_lat').length > 0){
    var lat = parseFloat($('#loc_lat').html()),
        lon = parseFloat($('#loc_lng').html());
    mapInit({lat: lat, lng: lon});
}
else if($('input#scenario_location_lat').val()){
    // Update the map with the given coordinates - Update Config Page
    updateCoordinates();
}
else if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
        var pos = {lat: position.coords.latitude, lng: position.coords.longitude};
        mapInit(pos);
    }, function() {
        console.log("Error occurred while tracking the user's current location");
        mapInit({lat: 32.783060, lng: -96.806670});
    });
} else {
    // Browser doesn't support Geolocation
    console.log("Browser doesn't support GeoLocation,; user's current location can't be tracked");
    mapInit({lat: 32.783060, lng: -96.806670});
}

function mapInit(pos){
    map.setOptions({
        center: pos,
        zoom: 12,
        mapTypeControl: false,
        zoomControl: true,
        zoomControlOptions: {
            position: google.maps.ControlPosition.LEFT_BOTTOM
        },
    });
    marker.setOptions({
        position: pos,
        map: map,
        draggable: draggable_map ? true : false,
        animation: google.maps.Animation.DROP
    });

    $.cookie('lat', pos.lat());
    $.cookie('lng', pos.lng());
}

$('input#scenario_location_lat').change(updateCoordinates);

$('input#scenario_location_lng').change(updateCoordinates);

function updateCoordinates() {
    var lat = $('input#scenario_location_lat').val();
    var lon = $('input#scenario_location_lng').val();
    if(ck_lat.test(lat) && ck_lon.test(lon))
        changeCenter(lat, lon);
}

function changeCenter(lat, lon) {
    var latlng = new google.maps.LatLng(lat, lon);
    mapInit(latlng);
}

// Events triggered by marker position change
marker.addListener('position_changed', function(){
    var latlng = marker.getPosition();
    $('input#scenario_location_lat').val(Number(latlng.lat().toFixed(6)));
    $('input#scenario_location_lng').val(Number(latlng.lng().toFixed(6)));
});

marker.addListener('dragend', function(){
    var latlng = marker.getPosition();
    map.panTo(latlng);
    $.cookie('lat', latlng.lat().toFixed(6));
    $.cookie('lng', latlng.lng().toFixed(6));
});

console.log();

$('#scenario_business_name').autocomplete({
    source: '/scenarios/get-restaurants.json',
    select: function(event, ui) {
        event.preventDefault();
        $('#scenario_business_name').val(ui.item.value);
        $('#scenario_zomato_restaurant_id').val(ui.item.res_id);
        $('#scenario_location_lat').val(ui.item.lat);
        $('#scenario_location_lng').val(ui.item.lng);
        $('#scenario_zomato_address').val(ui.item.address);
        $('#scenario_zomato_loc_city_id').val(ui.item.city_id);
        $('#scenario_zomato_loc_city').val(ui.item.city);
        $('#scenario_zomato_postal_code').val(ui.item.postal_code);
        $('#scenario_zomato_cuisines').val(ui.item.cuisines);
        $('#scenario_zomato_user_rating').val(ui.item.user_rating);
        $('#scenario_zomato_rating_text').val(ui.item.rating_text);
        $('#scenario_zomato_rating_color').val(ui.item.rating_color);
        $('#scenario_zomato_votes_count').val(ui.item.votes_count);
        $('#scenario_zomato_has_online_delivery').val(ui.item.has_online_delivery);
        $('#scenario_zomato_price_range').val(ui.item.price_range);
        $('#scenario_zomato_average_cost_for_two').val(ui.item.average_cost_for_two);
        $('#scenario_zomato_thumb').val(ui.item.thumb);
        updateCoordinates();
    },
    focus: function(event, ui) {
        event.preventDefault();
        $('#scenario_business_name').val(ui.item.label);
    }
});
