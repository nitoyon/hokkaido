app = angular.module 'PolygonEdit'

app.controller 'ListCtrl', ($scope, CommonData) ->
  $scope.data = CommonData
  $scope.selectedIds = []

  $scope.$watch 'selectedIds', (newValue, oldValue) ->
    CommonData.updateSelectedRegion(newValue)

  $scope.$watch 'data.selectedRegion', (newValue, oldValue) ->
    if newValue?
      if $scope.selectedIds.length != 1 || $scope.selectedIds[0] != newValue.id
        $scope.selectedIds = [newValue.id]
    else
      $scope.selectedIds = []

app.directive 'regionList', () ->
  templateUrl: 'templates/region-list.html'
