app = angular.module 'PolygonEdit'

app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.data = CommonData
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    CommonData.updateSelectedRegion(newValue)

app.directive 'regionList', () ->
  restrict: 'E'
  templateUrl: 'templates/region-list.html'
