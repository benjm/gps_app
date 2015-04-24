LatLng = google.maps.LatLng
Marker = google.maps.Marker
Map = google.maps.Map
LatLngBounds = google.maps.LatLngBounds
Polyline = google.maps.Polyline

#mode = 'ocado'
mode = 'demo'

class Bus
  constructor: (png, clr) ->
    @getPng = -> png
    @getClr = -> clr

black = new Bus 'black', '#111'
red = new Bus 'red', '#D11'
green = new Bus 'green', '#1D1'

getBusForPhone = (phone) ->
  switch phone
    when "HTC Desire C" then black
    when "GT-I8190N" then black
    when "blackberry" then black
    when "HTC Desire S" then red
    when "strawberry" then red
    else green

# cfg
maxLat = 51.7757
minLat = 51.755117
maxLng = -0.208826
minLng = -0.251999
#minLng = -0.235 # for testing

stationX = 51.76373
stationY = -0.215564
titanX = 51.762488
titanY = -0.243518
centerX = 51.764
centerY = -0.230
maxTrail = 5
jsonRefreshInterval = 11500
msPerSecond = 1000
dataUrl = "/gethistory/#{encodeURIComponent mode}?callback=?"

llStation = new LatLng stationX, stationY
llTitan = new LatLng titanX, titanY
center = new LatLng centerX, centerY
bl = new LatLng minLat, minLng
tr = new LatLng maxLat, maxLng
normalBounds = new LatLngBounds bl, tr

getRouteImage = (deviceId, n) ->
  debugger
  '/' + (getBusForPhone(deviceId).getPng() or 'green') + getAlphaString(n) + '.png'

#polyfill
zip = (left, right) -> [a, right[i]] for a, i in left


# TODO split up this function, it is too long
jsonHdlr = (myObject, map, markers, lines, old) ->

  $('#last-checked').text new Date

  outsideArray = for unsortedArray in myObject
    array = unsortedArray.sort((r0, r1) -> r1.timestamp.localeCompare(r0.timestamp))
    zippedArray = zip array, [undefined, array...]
    relevant = zippedArray.slice 0, maxTrail
    out = for [myInnerObject, oldObject], nr in relevant
      rlabel = myInnerObject.route
      ll = new LatLng myInnerObject.latitude, myInnerObject.longitude
      delta = myInnerObject.age # in what?
      console.log "checking for age: " + delta
      image = getRouteImage rlabel, nr
      route = rlabel + nr
      marker = (markers[route] ?=
        new Marker
          position: ll
          map: map
          title: route
          icon: image)
      marker.setPosition ll
      marker.setMap map
      if oldObject?
        oldLl = new LatLng oldObject.latitude, oldObject.longitude
        lines[route]?.setMap(null) # TODO investigate dangling lines
        op = getOpacity nr
        color = getBusForPhone(rlabel).getClr()
        line = new Polyline
          path: [oldLl, ll]
          strokeColor: color
          strokeOpacity: op
          strokeWeight: 2
          map: map
        lines[route] = line
      [delta, not normalBounds.contains ll]

    reductor = (last, [next, _]) ->
      if last and next
        Math.max(last, next)
      else
        last or next
    
    recent = out.reduce reductor, undefined

    if (lastRlabel = relevant[relevant.length - 1][0].route) # when does this not hold
      color = getBusForPhone(lastRlabel).getPng()
      markersLines = zip(lines, markers).slice((start = array.length), start + maxTrail)
      for [line, marker] in markersLines
        marker?.setMap(null)
        line?.setMap(null)
      if recent and recent > 60
        image = getRouteImage lastRlabel, 0
        $("##{color}").addClass('late').removeClass('on-time')
        $("##{color}").find('.time').text(formatInHms recent)
      else
        $("##{color}").addClass('on-time').removeClass('late')

    out

  flattenedOutsideArray = outsideArray.reduce ((a, b) -> a.concat(b)), []
  if(totLength = flattenedOutsideArray.length)
    $("#missing-bus-info").addClass("hide").removeClass("show")
    if(oneIsOutside = flattenedOutsideArray.some(([_, b]) -> b))
      normalZone.setMap map
      $("#one-is-outside").addClass("show").removeClass("hide")
    else
      normalZone.setMap null
      $("#one-is-outside").addClass("hide").removeClass("show")
  else
    $("#missing-bus-info").addClass("show").removeClass("hide")

  nEw = new Date
  delay = Math.max(jsonRefreshInterval - (nEw - old), 0)
  setTimeout (-> $.getJSON dataUrl, (d) -> jsonHdlr d, map, markers, lines, nEw), delay


initialize = ->
  mapOptions =
    zoom: 14
    center: center
  
  map = new Map $('#mapcanvas').get(0), mapOptions
  now = new Date
  new Marker
    position: llStation
    map: map
    title: 'Station'

  new Marker
    position: llTitan
    map: map
    title: 'Titan'

  $.getJSON dataUrl, ((jd) -> jsonHdlr jd, map, [], [], now)


# XXX is there a better way?
# eg Date::toLocaleString ?
formatInHms = (seconds) ->
  hms = [~~(seconds / 3600), ~~((seconds / 60) % 60), seconds % 60]
  [hstr, mstr, sstr] = (("0" + n).slice(-2) for n in hms)
  hstr + ':' + mstr + ':' + sstr

getAlphaString = (n) ->
  switch
    when n < 1 then ''
    when n < 2 then '75'
    when n < 3 then '50'
    else '25'

getOpacity = (n) ->
  switch
    when n < 2 then 0.4
    when n < 3 then 0.3
    when n < 4 then 0.2
    else 0.1

#google.maps.event.addDomListener window, 'load', initialize
window.onload = initialize


