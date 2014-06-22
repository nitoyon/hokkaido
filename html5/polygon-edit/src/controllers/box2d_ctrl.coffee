app = angular.module 'PolygonEdit'

app.controller 'Box2dCtrl', ($scope, $document, CommonData) ->
  null

app.directive 'box2d', () ->
  templateUrl: 'templates/box2d.html'
