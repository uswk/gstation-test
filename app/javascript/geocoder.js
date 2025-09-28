var geocoder;
var map;

function codeAddress() {
  geocoder = new google.maps.Geocoder();
  var address = document.getElementById("address").value;
  if (geocoder) {
    geocoder.geocode( { 'address': address,'region': 'jp'},
      function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
          var bounds = new google.maps.LatLngBounds();
          for (var r in results) {
            if (results[r].geometry) {
              var latlng = results[r].geometry.location;
              var centerpoint = new google.maps.LatLng(latlng.lat(), latlng.lng());
              //Gmaps.map.map.setCenter(centerpoint);
              map.setCenter(centerpoint);
            }
          }
        }else{
          alert("Geocode 取得に失敗しました reason: "         + status);
        }
      }
    );
  }
}

console.log("geocoder.js OK");""