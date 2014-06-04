app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.data = CommonData

  $scope.rename = () ->
    region = $scope.data.selectedRegion
    newName = window.prompt 'Enter new name', region.name
    if newName != null
      region.name = newName
      CommonData.save()

  $scope.add = () ->
    $scope.data.addingNewPolygon = true
    p = new Polygon()
    p.isClose = false
    $scope.data.selectedRegion.polygon = p

  $scope.ok = () ->
    $scope.data.selectedRegion.polygon.close()
    $scope.data.addingNewPolygon = false
    CommonData.save()

  $scope.cancel = () ->
    $scope.data.addingNewPolygon = false
    $scope.data.selectedRegion.polygon = null
    CommonData.save()

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
