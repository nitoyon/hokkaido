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

  $scope.cancel = () ->
    $scope.data.addingNewPolygon = false

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
