// - Box2dFlashAS3 2.0.2
// - Tweener 1.31.71
package{
import flash.display.*;
import flash.events.*;

[SWF(backgroundColor="#f0f3f9", width="450", height="350")]
public class GyaoBox2d extends Sprite{
	static public const WIDTH:Number = 450;
	static public const HEIGHT:Number = 350;

	static public const TITLE_STATE:int = 0;
	static public const PLAYING_STATE:int = 1;

	private var title:Title;
	private var playing:Playing;
	private var currentState:IState;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozGoStd-Bold.otf', fontName='KozGoPro', unicodeRange='U+0041-U+0043,U+0045,U+0047,U+0049,U+004B,U+004C,U+004F,U+0050,U+0052-U+0054,U+0059,U+843D,U+8DF3')]
	private var Gothic:Class;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozMinPro-Medium.otf', fontName='KozMinPro', unicodeRange='U+3046,U+304B,U+3053,U+3057,U+3059,U+3068,U+3069,U+306D,U+306E,U+307E,U+308B,U+3092,U+FF1F')]
	private var Mincho:Class;

	[Embed(source='out.bin',mimeType="application/octet-stream")]
	private var PrefClass:Class;

	public function GyaoBox2d(){
		// draw border
		graphics.lineStyle(1.5, 0x999999);
		graphics.beginFill(0xffffff);
		graphics.drawRect(0, 0, WIDTH, HEIGHT);
		graphics.endFill();

		title = new Title(this); title.visible = false; addChild(title);
		playing = new Playing(this); playing.visible = false; addChild(playing);
		setState(TITLE_STATE);
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
}
}

import flash.display.Sprite;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import flash.filters.*;
import flash.ui.Keyboard;
import flash.utils.setTimeout;
import flash.utils.clearTimeout;
import caurina.transitions.Tweener;
import Box2D.Dynamics.*;
import Box2D.Dynamics.Joints.*;
import Box2D.Collision.*;
import Box2D.Collision.Shapes.*;
import Box2D.Common.b2Settings;
import Box2D.Common.Math.*;

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
	private var main:GyaoBox2d;
	private var hitarea:Sprite;
	private var button:Button;
	
	public function Title(_main:GyaoBox2d){
		main = _main;
	}

	public function start():void{
		alpha = 1;

		var W:int = GyaoBox2d.WIDTH;
		var H:int = GyaoBox2d.HEIGHT;

		var preview:Sprite = new Sprite();
		var sprites:Array = Playing.createSprites(1.0);
		preview.addChild(sprites[0]).x = 28 / 2; sprites[0].y = 10 + 28 / 2;
		preview.addChild(sprites[1]).x = 28; sprites[1].y = 10;
		preview.addChild(sprites[2]).x = 36;
		preview.addChild(sprites[3]).x = 72 + 28 / 2; sprites[3].y = 10 + 28 / 2;
		var scale:Number = Math.max(preview.width, preview.height * .8);
		preview.scaleX = preview.scaleY = 1.8;
		preview.x = 20;
		preview.y = 60;
		addChild(preview);

		var tf:TextField = createText1()
		tf.x = 205;
		tf.y = 80;
		addChild(tf);

		tf = createText2()
		tf.x = 20;
		tf.y = 140;
		addChild(tf);

		hitarea = new Sprite();
		hitarea.graphics.beginFill(0, 0);
		hitarea.graphics.drawRect(0, 0, W, H);
		hitarea.graphics.endFill();
		hitarea.buttonMode = true;
		hitarea.mouseChildren = false;

		button = new Button(200, 80, 25, "START", 48);
		button.x = (GyaoBox2d.WIDTH - 200) / 2;
		button.y = GyaoBox2d.HEIGHT - 130;
		addChild(button);
		hitarea.addEventListener("rollOver", buttonRollOver);
		hitarea.addEventListener("rollOut", buttonRollOut);

		addChild(hitarea);
		addEventListener("click", clickHandler);
	}

	public function end():void{
		if (hitarea){
			hitarea.removeEventListener("rollOver", buttonRollOver);
			hitarea.removeEventListener("rollOut", buttonRollOut);
			removeEventListener("click", clickHandler);
		}

		Tweener.removeAllTweens();

		while (numChildren) removeChildAt(0);
		hitarea = null;
		button = null;
	}

	private function buttonRollOver(event:Event):void{ button.hover = true; }
	private function buttonRollOut(event:Event):void{ button.hover = false; }

	private function clickHandler(event:Event = null):void{
		main.setState(GyaoBox2d.PLAYING_STATE);
	}

	private static function createText1():TextField{
		var largeSize:int = 48, smallSize:int = 45;
		var str:String = <>
			<font face="KozMinPro" size={smallSize}>を</font><font face="KozGoPro" size={largeSize}>落</font><font face="KozMinPro" size={smallSize}>とすと</font>
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

	private static function createText2():TextField{
		var largeSize:int = 48, smallSize:int = 45;
		var str:String = <>
			<font face="KozMinPro" size={smallSize}>どう</font><font face="KozGoPro" size={largeSize}>跳</font><font face="KozMinPro" size={smallSize}>ね</font>
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
	private var main:GyaoBox2d;

	private var world:b2World;
	private var mouseJoint:b2MouseJoint;
	static public const SCALE:Number = 100;

	private var backButton:Button;
	private var replayButton:Button;
	private var nextButton:Button;
	private var prevButton:Button;

	private var timerId:uint;

	public function Playing(_main:GyaoBox2d):void{
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
		addBox2dPrefBody();

		enterFrameHandler(null);
		timerId = setTimeout(function():void{
			if (timerId == 0) return;
			timerId = 0;
			startBox2dAnimation();
		}, .5 * 1000);
	}

	public function end():void{
		removeEventListener("enterFrame", enterFrameHandler);
		Tweener.removeAllTweens();
		if (timerId != 0) clearTimeout(timerId);

		while (numChildren) removeChildAt(0);
		removeBox2dPrefBody();
		stage.removeEventListener("mouseMove", mouseMoveHandler);
		stage.removeEventListener("mouseUp", mouseUpHandler);
	}

	private function startBox2dAnimation():void{
		addEventListener("enterFrame", enterFrameHandler);

		// こう跳ねます
		var likeThis:LikeThis = new LikeThis();
		likeThis.alpha = 0;
		addChild(likeThis);

		Tweener.addTween(likeThis, {
			alpha: 1,
			delay: 15,
			time: 2,
			transition: 'easeInSine'
		});
		Tweener.addTween(likeThis, {
			alpha: 0,
			delay: 20,
			time: 3
		});
	}

	private const R:int = 30;

	private function enterFrameHandler(event:Event):void{
		world.Step(1 / 72, 10);

		for (var b:b2Body = world.GetBodyList(); b; b = b.GetNext()) {
			var sprite:Sprite = b.GetUserData() as Sprite;
			if(!sprite) continue;
			sprite.x = b.GetWorldCenter().x * SCALE;
			sprite.y = b.GetWorldCenter().y * SCALE;
			sprite.rotation = b.GetAngle() * 180 / Math.PI;
		}
	}

	// デバッグビューを有効にする
	private function enableDebugView():void{
		var debugDraw:b2DebugDraw = new b2DebugDraw();
		debugDraw.m_sprite = this;
		debugDraw.m_drawScale = SCALE; // 1mを100ピクセルにする
		debugDraw.m_fillAlpha = 1; // 不透明度
		debugDraw.m_lineThickness = 1; // 線の太さ
		debugDraw.m_drawFlags = b2DebugDraw.e_shapeBit;
		world.SetDebugDraw(debugDraw);
	}

	// 周囲の枠を作る
	private function createBox2dRoom():void{
		var WIDTH:Number = GyaoBox2d.WIDTH;
		var HEIGHT:Number = GyaoBox2d.HEIGHT;

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

	private function addBox2dPrefBody():void{
		var zoom:Number = 3;
		var SCALE:Number = Playing.SCALE / zoom;

		var sprites:Array = createSprites(zoom);
		var bodyDef:b2BodyDef = new b2BodyDef();
		var body:b2Body;
		var pos:b2Vec2;

		var R:Number = .84;
		var F:Number = .3;
		var LEFT:Number = 28;

		// G
		bodyDef.position.Set((LEFT + 28 / 2) / SCALE, (10 + 28 / 2) / SCALE);
		body = world.CreateBody(bodyDef);
		var shapeDef:b2CircleDef = new b2CircleDef();
		shapeDef.radius = 28 / 2 / SCALE;
		shapeDef.density = 1;
		shapeDef.restitution = R;
		shapeDef.friction = F;
		body.CreateShape(shapeDef);
		body.SetMassFromShapes();
		pos = body.GetLocalCenter();
		body.m_userData = wrapSprite(sprites[0], 0, 0);
		body.m_userData.buttonMode = true;
		body.m_userData.addEventListener("mouseDown", mouseDownHandler);

		// O
		bodyDef.position.Set((LEFT + 72 + 28 / 2) / SCALE, (10 + 28 / 2) / SCALE);
		body = world.CreateBody(bodyDef);
		shapeDef.radius = 28 / 2 / SCALE;
		shapeDef.density = 1;
		shapeDef.restitution = R;
		shapeDef.friction = F;
		body.CreateShape(shapeDef);
		body.SetMassFromShapes();
		body.m_userData = wrapSprite(sprites[3], 0, 0);
		body.m_userData.buttonMode = true;
		body.m_userData.addEventListener("mouseDown", mouseDownHandler);

		// Y
		bodyDef.position.Set((LEFT + 28) / SCALE, 10 / SCALE);
		body = world.CreateBody(bodyDef);
		var polDef:b2PolygonDef= new b2PolygonDef();
		polDef.density = 1;
		polDef.restitution = R;
		polDef.friction = F;
		polDef.vertices[0].Set(1 / SCALE, 1 / SCALE);
		polDef.vertices[1].Set(8 / SCALE, 1 / SCALE);
		polDef.vertices[2].Set(14 / SCALE, 18 / SCALE);
		polDef.vertices[3].Set(7 / SCALE, 18 / SCALE);
		polDef.vertexCount = 4;
		body.CreateShape(polDef);

		polDef.vertices[0].Set(1 / SCALE, 27 / SCALE);
		polDef.vertices[1].Set(17 / SCALE, 1 / SCALE);
		polDef.vertices[2].Set(24 / SCALE, 1 / SCALE);
		polDef.vertices[3].Set(8 / SCALE, 27 / SCALE);
		polDef.vertexCount = 4;
		body.CreateShape(polDef);
		body.SetMassFromShapes();
		pos = body.GetLocalCenter();
		body.m_userData = wrapSprite(sprites[1], -pos.x * SCALE * zoom, -pos.y * SCALE * zoom);
		body.m_userData.buttonMode = true;
		body.m_userData.addEventListener("mouseDown", mouseDownHandler);

		// A
		bodyDef.position.Set((LEFT + 36) / SCALE, 0 / SCALE);
		body = world.CreateBody(bodyDef);
		polDef= new b2PolygonDef();
		polDef.density = 1;
		polDef.restitution = R;
		polDef.friction = F;
		polDef.vertices[0].Set(23.5 / SCALE, 37 / SCALE);
		polDef.vertices[1].Set(23.5 / SCALE, 28 / SCALE);
		polDef.vertices[2].Set(31 / SCALE, 29 / SCALE);
		polDef.vertices[3].Set(31 / SCALE, 37 / SCALE);
		polDef.vertexCount = 4;
		body.CreateShape(polDef);
		polDef.vertices[0].Set(0 / SCALE, 48 / SCALE);
		polDef.vertices[2].Set(31 / SCALE, 29 / SCALE);
		polDef.vertices[1].Set(31 / SCALE, 0 / SCALE);
		polDef.vertexCount = 3;
		body.CreateShape(polDef);
		body.SetMassFromShapes();
		pos = body.GetLocalCenter();
		body.m_userData = wrapSprite(sprites[2], -pos.x * SCALE * zoom, -pos.y * SCALE * zoom);
		body.m_userData.buttonMode = true;
		body.m_userData.addEventListener("mouseDown", mouseDownHandler);

		return;
	}

	public static function createSprites(zoom:Number):Array{
		var G:Sprite = new Sprite();
		G.graphics.beginFill(0);
		G.graphics.drawCircle(0, 0, 28 / 2);
		G.graphics.drawCircle(0, 0, 14 / 2);
		G.graphics.endFill();
		G.graphics.beginFill(0xffffff);
		G.graphics.moveTo(13, -10);
		G.graphics.lineTo(-1, -3);
		G.graphics.lineTo(15, -3);
		G.graphics.endFill();
		G.graphics.beginFill(0);
		G.graphics.moveTo(-3, -3);
		G.graphics.lineTo(14, -3);
		G.graphics.lineTo(7, 2);
		G.graphics.endFill();
		G.scaleX = G.scaleY = zoom;

		var O:Sprite = new Sprite();
		O.graphics.beginFill(0xEF3042);
		O.graphics.drawCircle(0, 0, 28 / 2);
		O.graphics.drawCircle(0, 0, 14 / 2);
		O.graphics.endFill();
		O.scaleX = O.scaleY = zoom;

		var Y:Sprite = new Sprite();
		Y.graphics.beginFill(0x000000);
		Y.graphics.moveTo(1, 1);
		Y.graphics.lineTo(8, 1);
		Y.graphics.lineTo(13, 18);
		Y.graphics.lineTo(6, 18);
		Y.graphics.endFill();
		Y.graphics.beginFill(0x000000);
		Y.graphics.moveTo(1, 27);
		Y.graphics.lineTo(17, 1);
		Y.graphics.lineTo(24, 1);
		Y.graphics.lineTo(8, 27);
		Y.graphics.endFill();
		Y.scaleX = Y.scaleY = zoom;

		var A:Sprite = new Sprite();
		A.graphics.beginFill(0x000000);
		A.graphics.moveTo(0, 48);
		A.graphics.lineTo(23.5, 33);
		A.graphics.lineTo(23.5, 23);
		A.graphics.lineTo(18, 32);
		A.graphics.lineTo(23.5, 33);
		A.graphics.lineTo(23.5, 37);
		A.graphics.lineTo(31, 37);
		A.graphics.lineTo(31, 0);
		A.graphics.endFill();
		A.scaleX = A.scaleY = zoom;

		return [G, Y, A, O];
	}

	private function wrapSprite(s:Sprite, diffX:Number, diffY:Number):Sprite{
		var ret:Sprite = new Sprite();
		s.x = diffX;
		s.y = diffY;
		addChild(ret);
		if (s.parent) ret.parent.removeChild(s);
		ret.addChild(s);
		return ret;
	}

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

class LikeThis extends Sprite{
	public function LikeThis(){
		var W:int = GyaoBox2d.WIDTH;
		var H:int = GyaoBox2d.HEIGHT;

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
			filters = (_hover ? null : [mono]);
		}
	}

	public function Button(W:Number, H:Number, R:Number, label:String = "", size:int = 0){
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(W, H, Math.PI / 2);

		var bg:Sprite = new Sprite();

		bg.graphics.beginGradientFill("linear", [0xDDE9F4, 0xD5E4F1, 0xBAD2E8], [1, 1, 1],
			[0, 120, 136], matrix);
		bg.graphics.drawRoundRect(0, 0, W, H, R, R);
		bg.graphics.endFill();

		bg.filters = [new GlowFilter(0xFFFFBE, .5, 10, 10, 2, 1, true)];
		addChild(bg);

		var line:Sprite = new Sprite();
		line.graphics.lineStyle(3, 0xBAD2E8);
		line.graphics.drawRoundRect(0, 0, W, H, R, R);
		addChild(line);

		filters = [mono];
		buttonMode = true;
		mouseChildren = false;

		if (label != ""){
			var textField:TextField = new TextField();
			textField.selectable = false;
			textField.embedFonts = true;
			textField.autoSize = "left";
			textField.scaleX = 1.1;
			textField.htmlText = <font size={size} face="KozGoPro" color="#6B8399">{label}</font>.toXMLString();
			textField.x = (W - textField.width) / 2;
			textField.y = (H - textField.height) / 2 + size / 7;
			addChild(textField);
		}

		addEventListener("rollOver", buttonRollOver);
		addEventListener("rollOut", buttonRollOut);
		addEventListener("removed", function(event:Event):void{
			removeEventListener("rollOver", buttonRollOver);
			removeEventListener("rollOut", buttonRollOut);
			removeEventListener("removed", arguments.callee);
		});
	}

	protected function buttonRollOver(event:Event):void{
		hover = true;
	}

	protected function buttonRollOut(event:Event):void{
		hover = false;
	}
}

