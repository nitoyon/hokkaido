app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, $document, CommonData, Zoom) ->
  $scope.data = CommonData
  $scope.zoom = Zoom

  # drag map handler
  $scope.mapDrag = () ->
    event = d3.event
    p = Zoom.clientToWorld event.x, event.y
    $scope.$apply () ->
      $scope.zoom.x += event.dx
      $scope.zoom.y += event.dy

  # drag dot handler
  $scope.dotDrag = (dot) -> $scope.$apply () ->
    dot.x += d3.event.dx
    dot.y += d3.event.dy
    $scope.data.selectedRegion.polygon.updateGroups()

  $scope.mapClick = () -> $scope.$apply () ->
    return unless CommonData.addingNewPolygon

    event = d3.event.sourceEvent
    p = Zoom.clientToWorld event.offsetX, event.offsetY
    d = new Dot p.x, p.y
    CommonData.selectedRegion.polygon.addDot d

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
