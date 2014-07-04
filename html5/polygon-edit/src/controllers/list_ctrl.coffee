app = angular.module 'PolygonEdit'

app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.data = CommonData
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    allRegions = CommonData.prefs.getAllRegions()
    regions = []
    for id in newValue
      # find selected region
      p = _.filter allRegions, (region) ->
        region.id == id
      regions.push p[0] if p.length > 0
    CommonData.updateSelectedRegions regions

  $scope.$watch 'data.selectedRegions', (newValue, oldValue) ->
    $scope.selectedIds.length = 0
    if newValue?
      for region in newValue
        $scope.selectedIds.push region.id

app.directive 'regionList', () ->
  templateUrl: 'templates/region-list.html'
