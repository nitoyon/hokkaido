app = angular.module 'PolygonEdit'

app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.data = CommonData
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    CommonData.updateSelectedRegion(newValue)

app.directive 'regionList', () ->
  templateUrl: 'templates/region-list.html'
