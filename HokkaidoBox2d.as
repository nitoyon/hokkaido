package{
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import Box2D.Dynamics.*;
import Box2D.Dynamics.Joints.*;
import Box2D.Collision.*;
import Box2D.Collision.Shapes.*;
import Box2D.Common.b2Settings;
import Box2D.Common.Math.*;

[SWF(backgroundColor="#ffffff", width="450", height="350")]
public class HokkaidoBox2d extends Sprite{
	private var world:b2World;
	private var prefSprites:Array = [];
	private var mouseJoint:b2MouseJoint;

	private var prefIndex:int = 0;

	static public const SCALE:Number = 100;
	static public const WIDTH:Number = 450;
	static public const HEIGHT:Number = 350;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozGoPro-Medium.otf', fontName='KozGoPro', unicodeRange='U+0041,U+0052,U+0053,U+0054,U+4E09,U+4E95,U+4EAC,U+4F50,U+5150,U+5175,U+5206,U+5317,U+5343,U+53D6,U+53E3,U+548C,U+57CE,U+57FC,U+5927,U+5948,U+5A9B,U+5BAE,U+5BCC,U+5C71,U+5C90,U+5CA1,U+5CA9,U+5CF6,U+5D0E,U+5DDD,U+5E83,U+5E9C,U+5EAB,U+5F62,U+5FB3,U+611B,U+624B,U+65B0,U+6728,U+672C,U+6771,U+6803,U+6839,U+68A8,U+68EE,U+6B4C,U+6C96,U+6D77,U+6ECB,U+6F5F,U+718A,U+7389,U+7530,U+770C,U+77E5,U+77F3,U+795E,U+798F,U+79CB,U+7E04,U+7FA4,U+826F,U+8328,U+843D,U+8449,U+8CC0,U+8DF3,U+9053,U+90FD,U+91CD,U+91CE,U+9577,U+961C,U+962A,U+9752,U+9759,U+9999,U+99AC,U+9AD8,U+9CE5,U+9E7F')]
	private var Gothic:Class;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozMinPro-Medium.otf', fontName='KozMinPro', unicodeRange='U+3046,U+304B,U+3053,U+3059,U+3068,U+3069,U+306D,U+306E,U+307E,U+308B,U+3092,U+FF1F')]
	private var Mincho:Class;

	public function HokkaidoBox2d(){
		// draw border
		graphics.lineStyle(1, 0x999999);
		graphics.drawRect(0, 0, WIDTH, HEIGHT);

		// init Box2dFlashAs3
		initBox2d();

		showTitle();
		//startBox2d();
	}

	// タイトル画面を表示する
	private function showTitle():void{
		var title:Title = new Title(prefIndex);
		addChild(title);
		title.addEventListener("click", function(event:Event):void{
			title.removeEventListener("click", arguments.callee);
			removeChild(title);
			startBox2d();
		});
	}

	// 都道府県落下開始
	private function startBox2d():void{
		removeBox2dPrefBody();
		addBox2dPrefBody(prefIndex);

		var counter:int = 0;
		var likeThis:LikeThis = new LikeThis(prefIndex);
		likeThis.alpha = 0;
		addChild(likeThis);

		var start:int = 100;
		var length:int = 60;
		var end:int = 150;
		var alpha:Number = 1;

		addEventListener("enterFrame", function(event:Event):void{
			world.Step(1 / 36, 10);

			if(counter >= start && counter < start + length){
				likeThis.alpha = (counter - start) / length;
			}
			if(counter > end){
				alpha = likeThis.alpha = 1 - (counter - end) / length;
			}
			if(counter >= end + length + 30){
				removeEventListener("enterFrame", arguments.callee);
				while(numChildren) removeChildAt(0);

				prefIndex = (prefIndex + 1) % 47;
				showTitle();
				return;
			}

			for (var b:b2Body = world.GetBodyList(); b; b = b.GetNext()) {
				var sprite:Sprite = b.GetUserData() as Sprite;
				if(!sprite) continue;
				sprite.x = b.GetWorldCenter().x * SCALE;
				sprite.y = b.GetWorldCenter().y * SCALE;
				sprite.rotation = b.GetAngle() * 180 / Math.PI;
				sprite.alpha = alpha;

				if(b.IsSleeping() && Math.random() < .05){
/*					var m:Number = b.GetMass();
					var r1:Number = Math.pow(Math.random() - .5, 2);
					var r2:Number = Math.pow(Math.random(), 2)
					b.ApplyForce(new b2Vec2(5000 * r1 * (m / SCALE), (2000) * (m / SCALE)), b.GetLocalCenter());
*/				}
			}

			counter++;
		});
	}

	// box2d を初期化する
	private function initBox2d():void{
		// 世界を作る
		var worldAABB:b2AABB = new b2AABB();
		worldAABB.lowerBound.Set(-100, -100);
		worldAABB.upperBound.Set(100, 100);

		var gravity:b2Vec2 = new b2Vec2(0, 10);
		world = new b2World(worldAABB, gravity, true);

		// 部屋を作る
		createBox2dRoom();

		// デバッグビュー
		//enableDebugView();
	}

	private function enableDebugView():void{
		var debugDraw:b2DebugDraw = new b2DebugDraw();
		debugDraw.m_sprite = this;
		debugDraw.m_drawScale = SCALE; // 1mを100ピクセルにする
		debugDraw.m_fillAlpha = .8; // 不透明度
		debugDraw.m_lineThickness = 1; // 線の太さ
		debugDraw.m_drawFlags = b2DebugDraw.e_shapeBit;
		world.SetDebugDraw(debugDraw);
	}

	// 周囲の枠を作る
	private function createBox2dRoom():void{
		var floorHorizontalShapeDef:b2PolygonDef = new b2PolygonDef();
		floorHorizontalShapeDef.SetAsBox(WIDTH / SCALE, 1);

		var floorBodyDef:b2BodyDef = new b2BodyDef();
		floorBodyDef.position.Set(0, -1);
		var floor:b2Body = world.CreateBody(floorBodyDef);
		floor.CreateShape(floorHorizontalShapeDef);

		floorBodyDef.position.Set(0, HEIGHT / SCALE + 1);
		floor = world.CreateBody(floorBodyDef);
		floor.CreateShape(floorHorizontalShapeDef);

		var floorVerticalShapeDef:b2PolygonDef = new b2PolygonDef();
		floorVerticalShapeDef.SetAsBox(1, HEIGHT / SCALE + 1);

		floorBodyDef.position.Set(-1, -1);
		floor = world.CreateBody(floorBodyDef);
		floor.CreateShape(floorVerticalShapeDef);

		floorBodyDef.position.Set(WIDTH / SCALE + 1, -1);
		floor = world.CreateBody(floorBodyDef);
		floor.CreateShape(floorVerticalShapeDef);
	}

	// 都道府県を作る
	private function addBox2dPrefBody(prefIndex:int):void{
		// 都道府県を作る
		var bodyDef:b2BodyDef = new b2BodyDef();
		bodyDef.position.Set(1.7, 0);

		prefSprites = [];
		var zoom:Number = Prefs[prefIndex]['zoom'];
		for each(var area:Object in Prefs[prefIndex]['areas']){
			// box2d 上に凸包を作成
			var body:b2Body = world.CreateBody(bodyDef);
			createBox2dConvex(body, area['convex'], zoom);

			// 表示するSprite を作成
			var center:b2Vec2 = body.GetLocalCenter();
			body.m_userData = createAreaSprite(area['pt'], -center.x * SCALE, -center.y * SCALE, zoom);
			body.m_userData.buttonMode = true;
			body.m_userData.addEventListener("mouseDown", mouseDownHandler);
			addChild(body.m_userData);
			prefSprites.push(body.m_userData);
		}
	}

	// 都道府県を削除する
	private function removeBox2dPrefBody():void{
		for (var b:b2Body = world.GetBodyList(); b; b = b.GetNext()) {
			if (b.IsDynamic()){
				var s:Sprite = b.m_userData as Sprite;
				if (s){
					s.removeEventListener("mouseDown", mouseDownHandler);
					if (s.parent) s.parent.removeChild(s);
				}
				world.DestroyBody(b);
			}
		}
	}

	// エリアの凸包を作る
	private function createBox2dConvex(body:b2Body, convex:Array, zoom:Number):void{
		var shapeDef:b2PolygonDef= new b2PolygonDef();
		shapeDef.density = 1;
		shapeDef.restitution = .7;

		var counts:int = convex.length / 2;
		var start:int = 1;

		var points:Array = convex.concat();
		var x0:Number = points.shift(), y0:Number = points.shift();
		var y1:Number = points.pop(), x1:Number = points.pop();
		while(points.length){
			var pointsLeft:int = Math.min(points.length / 2 + 2, 8);
			shapeDef.vertices[0].Set(x0 / SCALE * zoom, y0 / SCALE * zoom);
			shapeDef.vertices[pointsLeft - 1].Set(x1 / SCALE * zoom, y1 / SCALE * zoom);

			for(var i:int = 2; i < pointsLeft; i++){
				if (i % 2 == 0){
					x0 = points.shift();
					y0 = points.shift();
					shapeDef.vertices[i / 2].Set(x0 / SCALE * zoom, y0 / SCALE * zoom);
				} else {
					y1 = points.pop();
					x1 = points.pop();
					shapeDef.vertices[pointsLeft - Math.floor(i / 2) - 1].Set(x1 / SCALE * zoom, y1 / SCALE * zoom);
				}
			}
			shapeDef.vertexCount = pointsLeft;
			body.CreateShape(shapeDef);
		}
		body.SetMassFromShapes();
	}

	// 都道府県番号とエリア番号から Sprite を作る
	public static function createAreaSprite(points:Array, centerX:Number, centerY:Number, zoom:Number):Sprite{
		var sprite:Sprite = new Sprite();
		sprite.graphics.lineStyle(1, 0x999999, 1, false, "none");
		sprite.graphics.beginFill(0xeeeeee);

		var moveFlag:Boolean = false;
		for(var i:int = 0; i < points.length / 2; i++){
			var x:Number = points[i * 2];
			var y:Number = points[i * 2 + 1];
			if(isNaN(x) || isNaN(y)){
				moveFlag = true;
			}else if(moveFlag){
				sprite.graphics.moveTo(x * zoom, y * zoom);
				moveFlag = false;
			}else{
				sprite.graphics.lineTo(x * zoom, y * zoom);
			}
		}

		sprite.graphics.endFill();
		sprite.x = centerX;
		sprite.y = centerY;

		var ret:Sprite = new Sprite();
		ret.addChild(sprite);
		return ret;
	}

	// マウス押下時
	private function mouseDownHandler(event:MouseEvent):void{
		var body:b2Body = GetBodyAtMouse(event.stageX, event.stageY);
		if(body){
			var md:b2MouseJointDef = new b2MouseJointDef();
			md.body1 = world.GetGroundBody();
			md.body2 = body;
			md.target.Set(event.stageX / SCALE, event.stageY / SCALE);
			md.maxForce = 30.0 * body.GetMass();
			md.timeStep = 1 / 24;
			mouseJoint = world.CreateJoint(md) as b2MouseJoint;
			body.WakeUp();

			stage.addEventListener("mouseMove", mouseMoveHandler);
			stage.addEventListener("mouseUp", mouseUpHandler);
		}
	}

	// ドラッグ中
	private function mouseMoveHandler(event:MouseEvent):void{
		mouseJoint.SetTarget(new b2Vec2(event.stageX / SCALE, event.stageY / SCALE));
	}

	// ドラッグ終了
	private function mouseUpHandler(event:MouseEvent):void{
		world.DestroyJoint(mouseJoint);
		mouseJoint = null;

		stage.removeEventListener("mouseMove", mouseMoveHandler);
		stage.removeEventListener("mouseUp", mouseUpHandler);
	}

	private var mousePVec:b2Vec2 = new b2Vec2();
	public function GetBodyAtMouse(mouseX:Number, mouseY:Number, includeStatic:Boolean = false):b2Body{
		mouseX /= SCALE;
		mouseY /= SCALE;

		// Make a small box.
		mousePVec.Set(mouseX, mouseY);
		var aabb:b2AABB = new b2AABB();
		aabb.lowerBound.Set(mouseX - 0.001, mouseY - 0.001);
		aabb.upperBound.Set(mouseX + 0.001, mouseY + 0.001);
		
		// Query the world for overlapping shapes.
		var k_maxCount:int = 10;
		var shapes:Array = new Array();
		var count:int = world.Query(aabb, shapes, k_maxCount);
		for (var i:int = 0; i < count; ++i){
			if (shapes[i].GetBody().IsStatic() == false || includeStatic){
				var tShape:b2Shape = shapes[i] as b2Shape;
				var inside:Boolean = tShape.TestPoint(tShape.GetBody().GetXForm(), mousePVec);
				if (inside){
					return tShape.GetBody();
				}
			}
		}
		return null;
	}
}
}

import flash.display.Sprite;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import flash.filters.*;

class Title extends Sprite{
	public function Title(prefIndex:int){
		var W:int = HokkaidoBox2d.WIDTH;
		var H:int = HokkaidoBox2d.HEIGHT;

		var tf:TextField = createText(Prefs[prefIndex]['name'])
		tf.x = W / 2;
		tf.y = 30;
		addChild(tf);

		var preview:Sprite = new Sprite();
		for each(var area:Object in Prefs[prefIndex]['areas']){
			var child:Sprite = HokkaidoBox2d.createAreaSprite(area['pt'], 0, 0, 1.0);
			preview.addChild(child);
		}
		var scale:Number = Math.max(preview.width, preview.height);
		preview.scaleX = preview.scaleY = W * .4 / scale;
		preview.x = W * .05;
		preview.y = (H - 100 - preview.height) / 2;
		addChild(preview);

		var button:Button = new Button(200, 80, 20);
		button.x = (HokkaidoBox2d.WIDTH - 200) / 2;
		button.y = HokkaidoBox2d.HEIGHT - 100;
		addChild(button);

		var clickable:Sprite = new Sprite();
		clickable.graphics.beginFill(0, 0);
		clickable.graphics.drawRect(0, 0, W, H);
		clickable.graphics.endFill();
		clickable.buttonMode = true;
		clickable.mouseChildren = false;
		addChild(clickable);
		clickable.addEventListener("rollOver", function(event:Event):void{ button.hover = true; });
		clickable.addEventListener("rollOut", function(event:Event):void{ button.hover = false; });
	}

	private static function createText(prefName:String):TextField{
		var largeSize:int = 48, smallSize:int = 45;
		var str:String = <>
			<font face="KozGoPro" size={largeSize}>{prefName}</font><font face="KozMinPro" size={smallSize}>を</font><br/>
			<font face="KozGoPro" size={largeSize}>落</font><font face="KozMinPro" size={smallSize}>とすと</font><br/>
			<font face="KozMinPro" size={smallSize}>どう</font><font face="KozGoPro" size={largeSize}>跳</font><font face="KozMinPro" size={smallSize}>ね</font><br/>
			<font face="KozMinPro" size={smallSize}>るのか？</font>
			</>.toString();

		var fmt:TextFormat = new TextFormat();
		fmt.leading = -20;

		var textField:TextField = new EmbedTextField();
		textField.defaultTextFormat = fmt;
		textField.width = 400;
		textField.height = 600;
		textField.wordWrap = true;
		textField.htmlText = str;
		return textField;
	}
}

class LikeThis extends Sprite{
	public function LikeThis(prefIndex:int){
		var W:int = HokkaidoBox2d.WIDTH;
		var H:int = HokkaidoBox2d.HEIGHT;

		// こう跳ねます
		var largeSize:int = 48, smallSize:int = 45;
		var str:String = <>
			<font face="KozMinPro" size={smallSize}>こう</font>
			<font face="KozGoPro" size={largeSize}>跳</font>
			<font face="KozMinPro" size={smallSize}>ねます</font>
			</>.toString();

		var textField:TextField = new EmbedTextField();
		textField.autoSize = "left";
		textField.htmlText = str;
		textField.x = (W - textField.width) / 2;
		textField.y = (H - textField.height) / 2;
		addChild(textField);

		// 右上
		largeSize = 14; smallSize = 12;
		var prefName:String = Prefs[prefIndex]['name'];
		str = <>
			<font face="KozGoPro" size={largeSize}>{prefName}</font><font face="KozMinPro" size={smallSize}>を</font>
			<font face="KozGoPro" size={largeSize}>落</font><font face="KozMinPro" size={smallSize}>とすと</font><br/>
			<font face="KozMinPro" size={smallSize}>どう</font><font face="KozGoPro" size={largeSize}>跳</font><font face="KozMinPro" size={smallSize}>ねるのか？</font>
			</>.toString();
		var fmt:TextFormat = new TextFormat();
		fmt.color = 0x999999;
		fmt.leading = -5;

		textField = new EmbedTextField();
		textField.defaultTextFormat = fmt;
		textField.autoSize = "left";
		textField.htmlText = str;
		textField.x = W - textField.width - 5;
		textField.y = 5;
		addChild(textField);
	}
}

class EmbedTextField extends TextField{
	public function EmbedTextField(){
		selectable = false;
		embedFonts = condenseWhite = multiline = true;
	}
}

class Button extends Sprite{
	private const WIDTH:int = 200;
	private const HEIGHT:int = 100;
	private const RADIUS:int = 25;

	private static const mono:ColorMatrixFilter = new ColorMatrixFilter([
		1 / 3, 1 / 3, 1 / 3, 0, 10,
		1 / 3, 1 / 3, 1 / 3, 0, 10,
		1 / 3, 1 / 3, 1 / 3, 0, 10,
		    0,     0,     0, 1, 0
	]);

	private var _hover:Boolean = false;
	public function get hover():Boolean{
		return _hover;
	}
	public function set hover(value:Boolean):void{
		if(_hover != value){
			_hover = value;
			filters = (_hover ? [] : [mono]);
		}
	}

	public function Button(W:Number, H:Number, r:Number){
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(W, H, Math.PI / 2);

		var bg:Sprite = new Sprite();

		bg.graphics.beginGradientFill("linear", [0xDDE9F4, 0xD5E4F1, 0xBAD2E8], [1, 1, 1],
			[0, 120, 136], matrix);
		bg.graphics.drawRoundRect(0, 0, W, H, RADIUS, RADIUS);
		bg.graphics.endFill();

		bg.filters = [new GlowFilter(0xFFFFBE, .5, 10, 10, 2, 1, true)];
		addChild(bg);

		var line:Sprite = new Sprite();
		line.graphics.lineStyle(3, 0xBAD2E8);
		line.graphics.drawRoundRect(0, 0, W, H, RADIUS, RADIUS);
		addChild(line);

		filters = [mono];

		var textField:TextField = new TextField();
		textField.selectable = false;
		textField.embedFonts = true;
		textField.autoSize = "left";
		textField.scaleX = 1.1;
		textField.htmlText = "<font size='48' face='KozGoPro' color='#6B8399'>START</font>";
		textField.x = (W - textField.width) / 2;
		textField.y = (H - textField.height) / 2 + 5;
		addChild(textField);
	}
}

