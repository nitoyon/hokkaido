app = angular.module 'PolygonEdit'

app.controller 'HeaderCtrl', ($scope, CommonData) ->
  $scope.data = CommonData

  $scope.rename = () ->
    region = $scope.data.selectedRegion
    newName = window.prompt 'Enter new name', region.name
    if newName != null
      region.name = newName
      CommonData.save()

  $scope.add = () ->
    $scope.data.addingNewPolygon = true
    $scope.data.selectedRegion.createPolygon()

  $scope.ok = () ->
    $scope.data.selectedRegion.polygon.close()
    $scope.data.addingNewPolygon = false
    CommonData.save()

  $scope.cancel = () ->
    $scope.data.addingNewPolygon = false
    $scope.data.selectedRegion.polygon = null
    CommonData.save()

  $scope.save = ->
    dat = JSON.stringify CommonData.prefs.serialize()
    window.open 'data:application/octet-stream,' + encodeURIComponent dat,
      '_new_window'

  $scope.load = ->
    value = window.prompt 'Paste saved content'
    if value != null
      CommonData.load value

app.directive 'headerToolbar', () ->
  templateUrl: 'templates/header-toolbar.html'
