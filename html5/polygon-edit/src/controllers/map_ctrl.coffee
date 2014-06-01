app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, CommonData) ->
  $scope.prefs = CommonData.prefs

app.directive 'regionMap', () ->
  restrict: 'E'
  templateUrl: 'templates/region-map.html'