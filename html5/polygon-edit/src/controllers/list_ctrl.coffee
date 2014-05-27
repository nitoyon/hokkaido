app = angular.module('PolygonEdit', [])

app.service 'CommonData', ($http) ->
  @prefs = new PrefList()
  @selectedRegion = null

  @updateSelectedRegion = (selectedIds) =>
    @selectedRegion?.isSelected = false
    if selectedIds.length == 0
      @selectedRegion = null
    else
      id = selectedIds[0]

      # find selected region
      p = _.filter @prefs.getAllRegions(), (region) ->
        region.id == id
      @selectedRegion = if p.length > 0 then p[0] else null
    @selectedRegion?.isSelected = true

  $http.get 'out.geojson'
  .success (data) =>
    projection = d3.geo
    .mercator()
    .scale 1200    # scale
    .rotate [-150,0,0]
    .translate [580, 1100]

    path = d3.geo.path().projection projection

    @prefs.parseJson data, path

  null


app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.prefs = CommonData.prefs
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    CommonData.updateSelectedRegion(newValue)
