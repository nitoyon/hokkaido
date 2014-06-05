app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, $document, CommonData, Zoom) ->
  $scope.data = CommonData
  $scope.zoom = Zoom
  $scope.selectedDot = null

  # drag map handler
  $scope.mapDrag = () ->
    event = d3.event
    p = Zoom.clientToWorld event.x, event.y
    $scope.$apply () ->
      $scope.zoom.move event.dx, event.dy

  # drag dot handler
  $scope.dotMove = (dot) -> $scope.$apply () ->
    dot.x += d3.event.dx
    dot.y += d3.event.dy
    $scope.data.selectedRegion.polygon.updateGroups()
    CommonData.save()

  # click dot handler
  $scope.dotSelect = (dot) -> $scope.$apply () ->
    $scope.selectedDot = dot
  $scope.$watch 'data.selectedRegion', () ->
    $scope.selectedDot = null

  # line click handler
  $scope.lineClick = (line, event) ->
    p = Zoom.clientToWorld event.offsetX, event.offsetY
    d = new Dot p.x, p.y
    $scope.selectedDot = d
    for region in CommonData.prefs.getAllRegions()
      region.polygon?.splitLine line, d

  $scope.mapClick = () -> $scope.$apply () ->
    return unless CommonData.addingNewPolygon

    event = d3.event.sourceEvent
    p = Zoom.clientToWorld event.offsetX, event.offsetY
    d = new Dot p.x, p.y
    CommonData.selectedRegion.polygon.addDot d

  # keyboard shortcut
  $document.bind 'keydown', (event) ->
    switch event.keyCode
      when 187 # +
        $scope.$apply () -> $scope.zoom.zoomUp()
      when 189 # -
        $scope.$apply () -> $scope.zoom.zoomDown()
      when 46  # del
        region = $scope.data.selectedRegion
        if $scope.data.selectedRegion && $scope.selectedDot?
          $scope.$apply () ->
            $scope.selectedDot.del()
            CommonData.save()


app.directive 'regionMap', () ->
  restrict: 'E'
  templateUrl: 'templates/region-map.html'
