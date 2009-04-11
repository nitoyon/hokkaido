package{
import flash.display.*;
import flash.events.*;
import flash.net.SharedObject;
import flash.utils.ByteArray;
import flash.ui.Keyboard;

[SWF(backgroundColor="#ffffff", width="450", height="350")]
public class HokkaidoBox2d extends Sprite{
	// prefIndex property
	private var _prefIndex:int = 0;
	public function get prefIndex():int{return _prefIndex;}
	public function set prefIndex(value:int):void{
		if (_prefIndex != value){
			_prefIndex = value;
			storage.data.pref = _prefIndex;
			dispatchEvent(new Event("prefIndexChanged"));
		}
	}

	private var storage:SharedObject;
	private var _started:Boolean = false;
	public function get started():Boolean{return _started;}
	public function set started(value:Boolean):void{_started = value;}

	static public const WIDTH:Number = 450;
	static public const HEIGHT:Number = 350;

	static public const TITLE_STATE:int = 0;
	static public const PLAYING_STATE:int = 1;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozGoStd-Bold.otf', fontName='KozGoPro', unicodeRange='U+0041,U+0052,U+0053,U+0054,U+4E09,U+4E95,U+4EAC,U+4F50,U+5150,U+5175,U+5206,U+5317,U+5343,U+53D6,U+53E3,U+548C,U+57CE,U+57FC,U+5927,U+5948,U+5A9B,U+5BAE,U+5BCC,U+5C71,U+5C90,U+5CA1,U+5CA9,U+5CF6,U+5D0E,U+5DDD,U+5E83,U+5E9C,U+5EAB,U+5F62,U+5FB3,U+611B,U+624B,U+65B0,U+6728,U+672C,U+6771,U+6803,U+6839,U+68A8,U+68EE,U+6B4C,U+6C96,U+6D77,U+6ECB,U+6F5F,U+718A,U+7389,U+7530,U+770C,U+77E5,U+77F3,U+795E,U+798F,U+79CB,U+7E04,U+7FA4,U+826F,U+8328,U+843D,U+8449,U+8CC0,U+8DF3,U+9053,U+90FD,U+91CD,U+91CE,U+9577,U+961C,U+962A,U+9752,U+9759,U+9999,U+99AC,U+9AD8,U+9CE5,U+9E7F')]
	private var Gothic:Class;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozMinPro-Medium.otf', fontName='KozMinPro', unicodeRange='U+3046,U+304B,U+3053,U+3059,U+3068,U+3069,U+306D,U+306E,U+307E,U+308B,U+3092,U+FF1F')]
	private var Mincho:Class;

	[Embed(source='out.bin',mimeType="application/octet-stream")]
	private var PrefClass:Class;

	private var title:Title;
	private var playing:Playing;
	private var currentState:IState;

	public function HokkaidoBox2d(){
		var bytes:ByteArray = new PrefClass();
		bytes.uncompress();
		PrefData = bytes.readObject();

		storage = SharedObject.getLocal("pref");
		prefIndex = storage.data.pref;

		// draw border
		graphics.lineStyle(1, 0x999999);
		graphics.drawRect(0, 0, WIDTH, HEIGHT);

		title = new Title(this);
		title.visible = false;
		addChild(title);
		playing = new Playing(this);
		playing.visible = false;
		addChild(playing);

		setState(TITLE_STATE);

		var lastWheel:Number = 0;
		stage.addEventListener("mouseWheel", function(event:MouseEvent):void{
			if (!started) return;

			// avoid firefox 3.0 dup wheel event problem
			var now:Number = new Date().getTime();
			if (now == lastWheel) return;
			lastWheel = now;

			prefIndex = (prefIndex + (event.delta < 0 ? 1 : -1) + 47) % 47;
			setState(TITLE_STATE);
		});
		stage.addEventListener("keyDown", function(event:KeyboardEvent):void{
			if (!started) return;
			if (event.keyCode == Keyboard.LEFT || event.keyCode == Keyboard.RIGHT){
				prefIndex = (prefIndex + (event.keyCode == Keyboard.LEFT ? -1 : 1) + 47) % 47;
				setState(TITLE_STATE);
			} else if (event.keyCode == Keyboard.ENTER && currentState == title){
				setState(PLAYING_STATE);
			}
		});
	}

	private function getStateObject(enum:int):IState{
		switch(enum){
			case TITLE_STATE: return title;
			case PLAYING_STATE: return playing;
			default: throw new Error('invalid parameter:' + enum);
		}
	}

	public function setState(stateNumber:int):void{
		var state:IState = getStateObject(stateNumber);

		if (state != currentState){
			if (currentState){
				currentState.visible = false;
				currentState.end();
			}

			state.visible = true;
			stage.focus = state as Sprite;
			currentState = state;
			state.start();
		}
	}

	// 都道府県番号とエリア番号から Sprite を作る
	public static function createAreaSprite(points:Array, centerX:Number, centerY:Number, zoom:Number):Sprite{
		var sprite:Sprite = new Sprite();
		sprite.graphics.lineStyle(1, 0x999999, 1, false, "none");
		sprite.graphics.beginFill(0xdddddd);

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
}
}

import flash.display.Sprite;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import flash.filters.*;
import flash.utils.setTimeout;
import flash.utils.clearTimeout;
import caurina.transitions.Tweener;
import Box2D.Dynamics.*;
import Box2D.Dynamics.Joints.*;
import Box2D.Collision.*;
import Box2D.Collision.Shapes.*;
import Box2D.Common.b2Settings;
import Box2D.Common.Math.*;

var PrefData:Array;

function assert(f:Boolean, msg:String = ""):void{
	if (!f) throw new Error(msg);
}

interface IState{
	function start():void;
	function end():void;
	function get visible():Boolean;
	function set visible(value:Boolean):void;
}

class Title extends Sprite implements IState{
	private var main:HokkaidoBox2d;
	private var hitarea:Sprite;
	private var button:Button;
	
	public function Title(_main:HokkaidoBox2d){
		main = _main;
	}

	public function start():void{
		assert(hitarea == null);
		assert(button == null);
		alpha = 1;

		var W:int = HokkaidoBox2d.WIDTH;
		var H:int = HokkaidoBox2d.HEIGHT;
		var prefIndex:int = main.prefIndex;
		var start:Boolean = !main.started

		var tf:TextField = createText(PrefBox2d[prefIndex]['name'])
		tf.x = W / 2;
		tf.y = 30 + (!start ? 50 : 0);
		addChild(tf);

		var preview:Sprite = new Sprite();
		for each(var area:Object in PrefData[prefIndex]){
			var child:Sprite = HokkaidoBox2d.createAreaSprite(area.p, 0, 0, 1.0);
			preview.addChild(child);
		}
		var scale:Number = Math.max(preview.width, preview.height);
		preview.scaleX = preview.scaleY = W * .4 / scale;
		preview.x = (W / 2 - preview.width) / 2;
		preview.y = (H - (start ? 100 : 0) - preview.height) / 2;
		addChild(preview);

		hitarea = new Sprite();
		hitarea.graphics.beginFill(0, 0);
		hitarea.graphics.drawRect(0, 0, W, H);
		hitarea.graphics.endFill();
		hitarea.buttonMode = true;
		hitarea.mouseChildren = false;

		if(start){
			button = new Button(200, 80, 20);
			button.x = (HokkaidoBox2d.WIDTH - 200) / 2;
			button.y = HokkaidoBox2d.HEIGHT - 100;
			addChild(button);
			hitarea.addEventListener("rollOver", buttonRollOver);
			hitarea.addEventListener("rollOut", buttonRollOut);
		}

		addChild(hitarea);

		addEventListener("click", clickHandler);
		if (!start){
			Tweener.addTween(this, {
				alpha: 0, 
				time: 2, 
				delay: 2.5,
				onComplete: clickHandler
			});
		}

		main.addEventListener("prefIndexChanged", prefIndexChangedHandler);
	}

	public function end():void{
		assert(hitarea != null);

		hitarea.removeEventListener("rollOver", buttonRollOver);
		hitarea.removeEventListener("rollOut", buttonRollOut);
		removeEventListener("click", clickHandler);
		main.removeEventListener("prefIndexChanged", prefIndexChangedHandler);

		Tweener.removeAllTweens();

		while (numChildren) removeChildAt(0);
		hitarea = null;
		button = null;
	}

	private function buttonRollOver(event:Event):void{ button.hover = true; }
	private function buttonRollOut(event:Event):void{ button.hover = false; }

	private function clickHandler(event:Event = null):void{
		main.started = true;
		main.setState(HokkaidoBox2d.PLAYING_STATE);
	}

	private function prefIndexChangedHandler(event:Event):void{
		end();
		start();
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

class Playing extends Sprite implements IState{
	private var main:HokkaidoBox2d;

	private var world:b2World;
	private var mouseJoint:b2MouseJoint;
	static public const SCALE:Number = 100;

	private var timerId:uint;

	public function Playing(_main:HokkaidoBox2d):void{
		main = _main;

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

	public function start():void{
		var prefIndex:int = main.prefIndex;
		addBox2dPrefBody(prefIndex);

		var subTitle:SubTitle = new SubTitle(prefIndex);
		subTitle.alpha = 0;
		addChild(subTitle);
		var sprites:Array = [];
		for (var i:int = 0; i < numChildren; i++) sprites.push(getChildAt(i));

		enterFrameHandler(null);
		Tweener.addTween(sprites, {
			alpha: 1,
			time: .3
		});
		timerId = setTimeout(function():void{
			if (timerId == 0) return;
			timerId = 0;
			sprites = null;
			startBox2dAnimation();
		}, .5 * 1000);
	}

	public function end():void{
		removeEventListener("enterFrame", enterFrameHandler);
		Tweener.removeAllTweens();
		if (timerId != 0) clearTimeout(timerId);

		while (numChildren) removeChildAt(0);
		removeBox2dPrefBody();
	}


	private function startBox2dAnimation():void{
		addEventListener("enterFrame", enterFrameHandler);

		var likeThis:LikeThis = new LikeThis();
		likeThis.alpha = 0;
		addChild(likeThis);

		var sprites:Array = [];
		for (var i:int = 0; i < numChildren; i++) sprites.push(getChildAt(i));

		Tweener.addTween(likeThis, {
			alpha: 1,
			delay: 5,
			time: 2,
			transition: 'lenear'
		});
		Tweener.addTween(sprites, {
			alpha: 0,
			delay: 8,
			time: 2,
			onComplete: function():void{
				if (!sprites) return;
				sprites = null;

				main.prefIndex = (main.prefIndex + 1) % 47;
				main.setState(HokkaidoBox2d.TITLE_STATE);
			}
		});
	}

	private function enterFrameHandler(event:Event):void{
		world.Step(1 / 36, 10);

		for (var b:b2Body = world.GetBodyList(); b; b = b.GetNext()) {
			var sprite:Sprite = b.GetUserData() as Sprite;
			if(!sprite) continue;
			sprite.x = b.GetWorldCenter().x * SCALE;
			sprite.y = b.GetWorldCenter().y * SCALE;
			sprite.rotation = b.GetAngle() * 180 / Math.PI;

			if(b.IsSleeping() && Math.random() < .05){
/*					var m:Number = b.GetMass();
				var r1:Number = Math.pow(Math.random() - .5, 2);
				var r2:Number = Math.pow(Math.random(), 2)
				b.ApplyForce(new b2Vec2(5000 * r1 * (m / SCALE), (2000) * (m / SCALE)), b.GetLocalCenter());
*/			}
		}
	}

	// デバッグビューを有効にする
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
		var WIDTH:Number = HokkaidoBox2d.WIDTH;
		var HEIGHT:Number = HokkaidoBox2d.HEIGHT;

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
		bodyDef.position.Set(1.5, 0.2);

		var prefSprites:Array = [];
		var zoom:Number = PrefBox2d[prefIndex]['zoom'];
		for each(var area:Object in PrefData[prefIndex]){
			// box2d 上に凸包を作成
			var body:b2Body = world.CreateBody(bodyDef);
			createBox2dConvex(body, area.c, prefIndex);

			// 表示するSprite を作成
			var center:b2Vec2 = body.GetLocalCenter();
			body.m_userData = HokkaidoBox2d.createAreaSprite(area.p, -center.x * SCALE, -center.y * SCALE, zoom);
			body.m_userData.buttonMode = true;
			body.m_userData.addEventListener("mouseDown", mouseDownHandler);
			body.m_userData.alpha = 0;
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
	private function createBox2dConvex(body:b2Body, convex:Array, prefIndex:int):void{
		var shapeDef:b2PolygonDef= new b2PolygonDef();
		shapeDef.density = 1;
		shapeDef.restitution = PrefBox2d[prefIndex]['r'] || 0.7;
		shapeDef.friction = PrefBox2d[prefIndex]['f'] || 0.2;
		var zoom:Number = PrefBox2d[prefIndex]['zoom'];

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


class SubTitle extends Sprite{
	public function SubTitle(prefIndex:int){
		var W:int = HokkaidoBox2d.WIDTH;
		var H:int = HokkaidoBox2d.HEIGHT;

		var largeSize:int = 14, smallSize:int = 12;
		var prefName:String = PrefBox2d[prefIndex]['name'];
		var str:String = <>
			<font face="KozGoPro" size={largeSize}>{prefName}</font><font face="KozMinPro" size={smallSize}>を</font>
			<font face="KozGoPro" size={largeSize}>落</font><font face="KozMinPro" size={smallSize}>とすと</font><br/>
			<font face="KozMinPro" size={smallSize}>どう</font><font face="KozGoPro" size={largeSize}>跳</font><font face="KozMinPro" size={smallSize}>ねるのか？</font>
			</>.toString();
		var fmt:TextFormat = new TextFormat();
		fmt.color = 0x999999;
		fmt.leading = -5;

		var textField:EmbedTextField = new EmbedTextField();
		textField.defaultTextFormat = fmt;
		textField.autoSize = "left";
		textField.htmlText = str;
		textField.x = W - textField.width - 5;
		textField.y = 5;
		addChild(textField);
	}
}

class LikeThis extends Sprite{
	public function LikeThis(){
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

