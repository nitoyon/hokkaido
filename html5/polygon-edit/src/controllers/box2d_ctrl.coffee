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

  getCenterOfPolygons = (polygons) ->
    [minX, minY] = [Number.MAX_VALUE, Number.MAX_VALUE]
    [maxX, maxY] = [Number.MIN_VALUE, Number.MIN_VALUE]
    for polygon in polygons
      for group in polygon.groups
        for dot in group
          minX = dot.x if dot.x < minX
          minY = dot.y if dot.y < minY
          maxX = dot.x if dot.x > maxX
          maxY = dot.y if dot.y > maxY
    return new Dot (minX + maxX) / 2, (minY + maxY) / 2

  addRegionBody = (polygon, center) ->
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
        vertices.push new b2Vec2 (dot.x - center.x) / SCALE + 8,
          (dot.y - center.y) / SCALE + 2

      shape = new b2PolygonShape()
      shape.SetAsVector vertices, vertices.length
      fixDef.shape = shape
      regionBody.CreateFixture fixDef

  step = () ->
    world.Step 1 / 60, 10, 10
    world.DrawDebugData()

  $scope.$watch 'data.selectedRegions', ->
    polygons = _.chain CommonData.selectedRegions
    .map (r) -> r.polygon
    .compact()
    .value()

    body = world.GetBodyList()
    while body
      world.DestroyBody body if body.GetType() == b2Body.b2_dynamicBody
      body = body.m_next

    center = getCenterOfPolygons polygons
    for polygon in polygons
      addRegionBody polygon, center

  $scope.$on '$destroy', ->
    clearInterval timer

  initWorld()
  initView()
  timer = setInterval ( -> step()), 10

  null


app.directive 'box2d', () ->
  templateUrl: 'templates/box2d.html'
