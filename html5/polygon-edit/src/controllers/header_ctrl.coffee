app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.data = CommonData

  $scope.rename = () ->
    region = $scope.data.selectedRegion
    newName = window.prompt 'Enter new name', region.name
    if newName != null
      region.name = newName

  $scope.add = () ->
    $scope.data.addingNewPolygon = true
    p = new Polygon()
    p.isClose = false
    $scope.data.selectedRegion.polygon = p

  $scope.ok = () ->
    $scope.data.selectedRegion.polygon.isClose = true
    $scope.data.addingNewPolygon = false

  $scope.cancel = () ->
    $scope.data.addingNewPolygon = false
    $scope.data.selectedRegion.polygon = null

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
