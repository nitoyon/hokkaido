app = angular.module 'PolygonEdit'

app.controller 'MapCtrl', ($scope, $document, CommonData, Zoom) ->
  $scope.data = CommonData
  $scope.zoom = Zoom
  # dot or inner line
  $scope.selectedItem = null
  $scope.innerLineMode = null

  # drag map handler
  $scope.mapDrag = () ->
    event = d3.event
    p = Zoom.clientToWorld event.x, event.y
    $scope.$apply () ->
      $scope.zoom.move event.dx, event.dy

  # drag start dot handler
  # enter "inner line" mode when a dot of the selected region is dragged
  # with Alt key
  $scope.dotDragStart = (dot) ->
    event = d3.event.sourceEvent
    polygon = $scope.data.selectedRegion?.polygon
    if polygon? && polygon.contains(dot) && event.altKey
      $scope.$apply ->
        $scope.innerLineMode =
          start: dot
          startElm: event.srcElement
          endCur:
            x: dot.x
            y: dot.y
          endPos:
            x: dot.x
            y: dot.y
          end: null
          candidate: polygon.getInnerLineCandidates dot

  # drag dot handler
  $scope.dotDrag = (dot) -> $scope.$apply () ->
    if $scope.innerLineMode?
      innerLineMove()
    else
      dotMove dot

  # drag end dot handler
  $scope.dotDragEnd = (dot) ->
    if $scope.innerLineMode?
      $scope.$apply -> innerLineMoveEnd()

  $scope.dotMouseOver = (dot) ->
    if $scope.innerLineMode?
      $scope.innerLineMode.end = dot

  dotMove = (dot) ->
    dot.x += d3.event.dx
    dot.y += d3.event.dy
    for polygon in CommonData.prefs.getAllPolygons()
      polygon.updateGroups() if polygon.contains dot
    CommonData.save()

  innerLineMove = ->
    mode = $scope.innerLineMode
    mode.endCur.x += d3.event.dx
    mode.endCur.y += d3.event.dy

    if mode.end?
      mode.endPos.x = mode.end.x
      mode.endPos.y = mode.end.y
    else
      mode.endPos.x = mode.endCur.x
      mode.endPos.y = mode.endCur.y
    return

  innerLineMoveEnd = ->
    mode = $scope.innerLineMode
    if mode.end?
      polygon = $scope.data.selectedRegion?.polygon
      polygon.addInnerLine mode.start, mode.end
      CommonData.save()

    $scope.innerLineMode = null

  # click dot handler
  $scope.dotClick = (dot) -> $scope.$apply () ->
    if CommonData.addingNewPolygon
      CommonData.selectedRegion.polygon.addDot dot

    $scope.selectedItem = dot

  # outer line click handler
  $scope.outerLineClick = (line, event) ->
    p = Zoom.clientToWorld event.offsetX, event.offsetY
    d = new Dot p.x, p.y
    $scope.selectedItem = d
    for region in CommonData.prefs.getAllRegions()
      region.polygon?.splitLine line, d

  $scope.innerLineClick = (line) ->
    $scope.selectedItem = line

  $scope.mapClick = () -> $scope.$apply () ->
    unless CommonData.addingNewPolygon
      $scope.selectedItem = null
      return

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
        if $scope.selectedItem?
          $scope.$apply () ->
            item = $scope.selectedItem
            if item instanceof Dot
              item.del()
            else if item instanceof Line
              $scope.data.selectedRegion?.polygon?.deleteInnerLine item
            CommonData.save()


app.directive 'regionMap', () ->
  restrict: 'E'
  templateUrl: 'templates/region-map.html'
