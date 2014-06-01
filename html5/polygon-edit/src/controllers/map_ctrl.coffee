app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, $document, CommonData, Zoom) ->
  $scope.prefs = CommonData.prefs
  $scope.zoom = Zoom

  # drag map handler
  $scope.mapDrag = () ->
    event = d3.event
    p = Zoom.clientToWorld event.x, event.y
    $scope.$apply () ->
      $scope.zoom.x += event.dx
      $scope.zoom.y += event.dy

  # keyboard shortcut for '+' & '-'
  $document.bind 'keydown', (event) ->
    switch event.keyCode
      when 187 # +
        $scope.$apply () -> $scope.zoom.zoomUp()
      when 189 # -
        $scope.$apply () -> $scope.zoom.zoomDown()


app.directive 'regionMap', () ->
  restrict: 'E'
  templateUrl: 'templates/region-map.html'
