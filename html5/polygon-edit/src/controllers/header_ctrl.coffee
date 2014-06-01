app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.selectedRegion = CommonData.selectedRegion

  # watch CommonData.selectedRegion
  $scope.$watch(
    () -> CommonData.selectedRegion
    (val) -> $scope.selectedRegion = val)

  $scope.rename = () ->
    alert('rename')

  $scope.add = () ->
    alert('add')

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
