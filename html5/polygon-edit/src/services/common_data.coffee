app = angular.module('PolygonEdit')

app.service 'CommonData', ($http) ->
  @prefs = new PrefList()
  @selectedRegions = []
  @selectedRegion = null
  @previewing = false
  @addingNewPolygon = false

  @updateSelectedRegions = (regions) =>
    @selectedRegions = regions
    if regions.length > 0
      @selectedRegion = regions[0]
    else
      @selectedRegion = null

  @save = () =>
    localStorage.prefs = JSON.stringify(@prefs.serialize())

  @load = (value) =>
    value = value || localStorage.prefs
    @prefs.deserialize JSON.parse value if value

  $http.get 'out.geojson'
  .success (data) =>
    projection = d3.geo
    .mercator()
    .scale 1200    # scale
    .rotate [-150,0,0]
    .translate [580, 1100]

    path = d3.geo.path().projection projection

    @prefs.parseJson data, path
    @load()

  null
