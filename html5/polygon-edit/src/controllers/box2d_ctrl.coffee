app = angular.module 'PolygonEdit'

app.controller 'Box2dCtrl', ($scope, $document, CommonData) ->
  $scope.data = CommonData

  b2Vec2 = Box2D.Common.Math.b2Vec2
  b2BodyDef = Box2D.Dynamics.b2BodyDef
  b2Body = Box2D.Dynamics.b2Body
  b2FixtureDef = Box2D.Dynamics.b2FixtureDef
  b2Fixture = Box2D.Dynamics.b2Fixture
  b2World = Box2D.Dynamics.b2World
  b2MassData = Box2D.Collision.Shapes.b2MassData
  b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
  b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
  b2DebugDraw = Box2D.Dynamics.b2DebugDraw
  SCALE = 10

  world = new b2World new b2Vec2(0, 10), true

  initWorld = () ->
    fixDef = new b2FixtureDef()
    fixDef.density = 1.0
    fixDef.friction = 0.71
    fixDef.restitution = 0.12

    # create ground
    bodyDef = new b2BodyDef()
    bodyDef.type = b2Body.b2_staticBody
    bodyDef.position.x = 8
    bodyDef.position.y = 13
    body = world.CreateBody bodyDef

    fixDef.shape = new b2PolygonShape()
    fixDef.shape.SetAsEdge new b2Vec2(-8, 0), new b2Vec2(8, 0)
    body.CreateFixture fixDef
    fixDef.shape.SetAsEdge new b2Vec2(-8, 0), new b2Vec2(-8, -10)
    body.CreateFixture fixDef
    fixDef.shape.SetAsEdge new b2Vec2(8, 0), new b2Vec2(8, -10)
    body.CreateFixture fixDef

  # setup debug draw
  initView = () ->
    ctx = $document[0].getElementById("preview").getContext("2d")
    debugDraw = new b2DebugDraw()
    debugDraw.SetSprite ctx
    debugDraw.SetDrawScale 25
    debugDraw.SetFillAlpha 1
    debugDraw.SetLineThickness 1.0
    debugDraw.SetFlags b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit
    world.SetDebugDraw debugDraw

  addRegionBody = (polygon) ->
    bodyDef = new b2BodyDef()
    bodyDef.type = b2Body.b2_dynamicBody
    regionBody = world.CreateBody bodyDef

    fixDef = new b2FixtureDef()
    fixDef.density = 5.0
    fixDef.friction = 0.1
    fixDef.restitution = 0.9

    # create polygon
    for group in polygon.groups
      vertices = []
      for dot in group
        vertices.push new b2Vec2 dot.x / SCALE, dot.y / SCALE

      shape = new b2PolygonShape()
      shape.SetAsVector vertices, vertices.length
      fixDef.shape = shape
      regionBody.CreateFixture fixDef

    # move body so that its center is placed at (4, 3)
    center = regionBody.GetLocalCenter()
    newPos = new b2Vec2(-center.x + 4, -center.y + 3)
    regionBody.SetPosition newPos

  step = () ->
    world.Step 1 / 60, 10, 10
    world.DrawDebugData()

  $scope.$watch 'data.selectedRegion', ->
    polygon = CommonData.selectedRegion?.polygon
    return unless polygon

    addRegionBody polygon

  $scope.$on '$destroy', ->
    clearInterval timer

  initWorld()
  initView()
  timer = setInterval ( -> step()), 10

  null


app.directive 'box2d', () ->
  templateUrl: 'templates/box2d.html'
