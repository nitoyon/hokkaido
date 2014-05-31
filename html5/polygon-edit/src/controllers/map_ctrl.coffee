app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, CommonData) ->
  $scope.prefs = CommonData.prefs
