app = angular.module 'PolygonEdit'

app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.prefs = CommonData.prefs
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    CommonData.updateSelectedRegion(newValue)

app.directive 'regionList', () ->
  restrict: 'E'
  templateUrl: 'templates/region-list.html'
