app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.selectedRegion = CommonData.selectedRegion

  # watch CommonData.selectedRegion
  $scope.$watch(
    () -> CommonData.selectedRegion
    (val) -> $scope.selectedRegion = val)

  $scope.rename = () ->
    region = $scope.selectedRegion
    newName = window.prompt 'Enter new name', region.name
    if newName != null
      region.name = newName

  $scope.add = () ->
    alert('add')

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
