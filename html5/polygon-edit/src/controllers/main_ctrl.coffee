app = angular.module 'PolygonEdit'

app.controller 'MainCtrl', ($scope, CommonData) ->
  $scope.data = CommonData
