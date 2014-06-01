app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.prefs = CommonData.prefs

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
