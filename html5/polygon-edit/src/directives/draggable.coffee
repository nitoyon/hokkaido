app = angular.module 'PolygonEdit'

# Draggable directive with D3.js
#
# HTML:
#     <div draggable draggable-ondrag="drag()"></div>
#
# JS:
#     scope.drag = function() {
#       var event = d3.event;
#       // ...
#     }
app.directive 'draggable', () ->
  scope:
    onDragStart: '&draggableOndragstart'
    onDrag: '&draggableOndrag'
    onDragEnd: '&draggableOndragend'
    onClick: '&draggableOnclick'

  link: (scope, element, attrs, controller) ->
    dragging = dragMoved = false

    drag = d3.behavior.drag()
    .on "dragstart", () ->
      dragging = dragMoved = false

      # drag the most foreground draggable object
      d3.event.sourceEvent.stopPropagation()
    .on "dragend", (d, i) =>
      if !dragMoved
        scope.onClick()
      else
        scope.onDragEnd()
    .on "drag", (d, i) =>
      if !dragging
        # skip first event (triggered on mouse down)
        dragging = true
        return
      else if !dragMoved
        # trigger onDragStart on first move
        dragMoved = true
        scope.onDragStart()
      scope.onDrag()

    d3.select(element[0]).call drag
