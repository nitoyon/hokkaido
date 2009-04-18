// - Box2dFlashAS3 2.0.2
// - Tweener 1.31.71
package{
import flash.display.*;
import flash.events.*;
//import flash.net.SharedObject;
import flash.utils.ByteArray;
import flash.external.ExternalInterface;

[SWF(backgroundColor="#f0f3f9", width="450", height="350")]
public class HokkaidoBox2d extends Sprite{
	// prefIndex property
	private var _prefIndex:int = 0;
	public function get prefIndex():int{return _prefIndex;}
	public function set prefIndex(value:int):void{
		if (_prefIndex != value){
			_prefIndex = value;
			//if(storage) storage.data.pref = _prefIndex;
			dispatchEvent(new Event("prefIndexChanged"));
		}
	}

	private var _started:Boolean = false;
	public function get started():Boolean{return _started;}
	public function set started(value:Boolean):void{_started = value;}

	private var _autoPlay:Boolean = true;
	public function get autoPlay():Boolean{return _autoPlay;}
	public function set autoPlay(value:Boolean):void{_autoPlay = value;}

	public var autoRepeat:Boolean = false;

	static public const WIDTH:Number = 450;
	static public const HEIGHT:Number = 350;

	static public const TITLE_STATE:int = 0;
	static public const PLAYING_STATE:int = 1;
	static public const INDEX_STATE:int = 2;

	private var title:Title;
	private var playing:Playing;
	private var index:Index;
	private var currentState:IState;

	//private var storage:SharedObject;
	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozGoStd-Bold.otf', fontName='KozGoPro', unicodeRange='U+0041-U+0043,U+0045,U+0049,U+004B,U+004C,U+0050,U+0052-U+0054,U+0059,U+4E09,U+4E95,U+4EAC,U+4F50,U+5150,U+5175,U+5206,U+5317,U+5343,U+53D6,U+53E3,U+548C,U+57CE,U+57FC,U+5927,U+5948,U+5A9B,U+5BAE,U+5BCC,U+5C71,U+5C90,U+5CA1,U+5CA9,U+5CF6,U+5D0E,U+5DDD,U+5E83,U+5E9C,U+5EAB,U+5F62,U+5FB3,U+611B,U+624B,U+65B0,U+6728,U+672C,U+6771,U+6803,U+6839,U+68A8,U+68EE,U+6B4C,U+6C96,U+6D77,U+6ECB,U+6F5F,U+718A,U+7389,U+7530,U+770C,U+77E5,U+77F3,U+795E,U+798F,U+79CB,U+7E04,U+7FA4,U+826F,U+8328,U+843D,U+8449,U+8CC0,U+8DF3,U+9053,U+90FD,U+91CD,U+91CE,U+9577,U+961C,U+962A,U+9752,U+9759,U+9999,U+99AC,U+9AD8,U+9CE5,U+9E7F')]
	private var Gothic:Class;

	[Embed(source='C:/Program Files/Common Files/Adobe/Fonts/KozMinPro-Medium.otf', fontName='KozMinPro', unicodeRange='U+3046,U+304B,U+3053,U+3057,U+3059,U+3068,U+3069,U+306D,U+306E,U+307E,U+308B,U+3092,U+FF1F')]
	private var Mincho:Class;

	[Embed(source='out.bin',mimeType="application/octet-stream")]
	private var PrefClass:Class;

	public function HokkaidoBox2d(){
		var bytes:ByteArray = new PrefClass();
		bytes.uncompress();
		PrefData = bytes.readObject();

		if (ExternalInterface.available){
			autoRepeat = ExternalInterface.call("window._hokkaido_auto_repeat") == true;
			if (ExternalInterface.call("window._hokkaido_random")){
				for(var i:int = 0; i < PrefData.length; i++){
					var n:int = Math.random() * (PrefData.length - i) + i;
					var tmp:Object = PrefData[i];
					PrefData[i] = PrefData[n];
					PrefData[n] = tmp;
					tmp = PrefBox2d[i];
					PrefBox2d[i] = PrefBox2d[n];
					PrefBox2d[n] = tmp;
				}
			}
		}
		started ||= autoRepeat;

		//storage = SharedObject.getLocal("pref");
		//prefIndex = storage.data.pref;

		// draw border
		graphics.lineStyle(1.5, 0x999999);
		graphics.beginFill(0xffffff);
		graphics.drawRect(0, 0, WIDTH, HEIGHT);
		graphics.endFill();

		title = new Title(this); title.visible = false; addChild(title);
		playing = new Playing(this); playing.visible = false; addChild(playing);
		index = new Index(this); index.visible = false; addChild(index);
		setState(TITLE_STATE);

		var lastWheel:Number = 0;
		stage.addEventListener("mouseWheel", function(event:MouseEvent):void{
			// avoid firefox 3.0 dup wheel event problem
			var now:Number = new Date().getTime();
			if (now == lastWheel) return;
			lastWheel = now;
			currentState.wheelHandler(event);
		});
		stage.addEventListener("keyDown", function(event:KeyboardEvent):void{
			currentState.keyHandler(event);
		});
	}

	private function getStateObject(enum:int):IState{
		switch(enum){
			case TITLE_STATE: return title;
			case PLAYING_STATE: return playing;
			case INDEX_STATE: return index;
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
		sprite.graphics.beginFill(0xcde0a7);

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

var PrefData:Array;

function assert(f:Boolean, msg:String = ""):void{
	if (!f) throw new Error(msg);
}

interface IState{
	function start():void;
	function end():void;
	function keyHandler(event:KeyboardEvent):void;
	function wheelHandler(event:MouseEvent):void;
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
		alpha = 1;

		var W:int = HokkaidoBox2d.WIDTH;
		var H:int = HokkaidoBox2d.HEIGHT;
		var prefIndex:int = main.prefIndex;
		var start:Boolean = !main.started

		var preview:Sprite = new Sprite();
		for each(var area:Object in PrefData[prefIndex]){
			var child:Sprite = HokkaidoBox2d.createAreaSprite(area.p, 0, 0, 1.0);
			preview.addChild(child);
		}
		var scale:Number = Math.max(preview.width, preview.height * .8);
		preview.scaleX = preview.scaleY = W * .4 / scale;
		preview.x = (W / 2 - preview.width) / 2;
		preview.y = (H - (start ? 100 : 0) - preview.height) / 2;
		addChild(preview);

		var tf:TextField = createText(PrefBox2d[prefIndex].name)
		tf.x = W / 2;
		tf.y = 30 + (!start ? 41 : 0);
		addChild(tf);

		if (PrefBox2d[prefIndex].name.length > 3){
			tf.x -= 15;
			preview.x -= 8;
		}

		if(start){
			hitarea = new Sprite();
			hitarea.graphics.beginFill(0, 0);
			hitarea.graphics.drawRect(0, 0, W, H);
			hitarea.graphics.endFill();
			hitarea.buttonMode = true;
			hitarea.mouseChildren = false;

			button = new Button(200, 80, 25, "START", 48);
			button.x = (HokkaidoBox2d.WIDTH - 200) / 2;
			button.y = HokkaidoBox2d.HEIGHT - 100;
			addChild(button);
			hitarea.addEventListener("rollOver", buttonRollOver);
			hitarea.addEventListener("rollOut", buttonRollOut);

			addChild(hitarea);
			addEventListener("click", clickHandler);
		} else {
			if (!main.autoRepeat){
				button = new Button(80, 25, 15, "SKIP", 14);
				button.x = W - 110;
				button.y = H - 40;
				addChild(button);
				button.addEventListener("click", buttonClickHandler);
			}

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
		if (hitarea){
			hitarea.removeEventListener("rollOver", buttonRollOver);
			hitarea.removeEventListener("rollOut", buttonRollOut);
			removeEventListener("click", clickHandler);
		}
		main.removeEventListener("prefIndexChanged", prefIndexChangedHandler);
		if (button) button.removeEventListener("click", buttonClickHandler);

		Tweener.removeAllTweens();

		while (numChildren) removeChildAt(0);
		hitarea = null;
		button = null;
	}

	public function keyHandler(event:KeyboardEvent):void{
		if (!main.started || !event.ctrlKey || !event.shiftKey) return;
		switch (event.keyCode){
			case Keyboard.LEFT:
			case Keyboard.RIGHT:
				main.prefIndex = (main.prefIndex + (event.keyCode == Keyboard.LEFT ? -1 : 1) + 47) % 47;
				end(); start();
				break;
			case Keyboard.ENTER:
				main.setState(HokkaidoBox2d.PLAYING_STATE);
				break;
		}
	}

	public function wheelHandler(event:MouseEvent):void{
		if (!main.started || !event.ctrlKey || !event.shiftKey) return;
		main.prefIndex = (main.prefIndex + (event.delta < 0 ? 1 : -1) + 47) % 47;
		end(); start();
	}

	private function buttonRollOver(event:Event):void{ button.hover = true; }
	private function buttonRollOut(event:Event):void{ button.hover = false; }

	private function clickHandler(event:Event = null):void{
		main.started = true;
		main.setState(HokkaidoBox2d.PLAYING_STATE);
	}

	private function buttonClickHandler(event:Event):void{
		main.setState(HokkaidoBox2d.INDEX_STATE);
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

	private var backButton:Button;
	private var replayButton:Button;
	private var nextButton:Button;
	private var prevButton:Button;

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
		if (main.autoPlay){
			alpha = 0;
			Tweener.addTween(this, {
				alpha: 1,
				time: .8
			});
		} else {
			alpha = 1;
		}

		var prefIndex:int = main.prefIndex;
		addBox2dPrefBody(prefIndex);

		var subTitle:SubTitle = new SubTitle(prefIndex);
		addChild(subTitle);

		enterFrameHandler(null);
		timerId = setTimeout(function():void{
			if (timerId == 0) return;
			timerId = 0;
			startBox2dAnimation();
		}, .5 * 1000);

		if (!main.autoPlay) addButtons();
		addEventListener("click", clickHandler);
	}

	public function end():void{
		removeEventListener("enterFrame", enterFrameHandler);
		Tweener.removeAllTweens();
		if (timerId != 0) clearTimeout(timerId);

		while (numChildren) removeChildAt(0);
		removeBox2dPrefBody();
		stage.removeEventListener("mouseMove", mouseMoveHandler);
		stage.removeEventListener("mouseUp", mouseUpHandler);
		removeEventListener("click", clickHandler);
	}

	public function keyHandler(event:KeyboardEvent):void{
		if (main.autoPlay && (!event.ctrlKey || !event.shiftKey)) return;

		switch (event.keyCode){
			case Keyboard.LEFT:
			case Keyboard.RIGHT:
				main.prefIndex = (main.prefIndex + (event.keyCode == Keyboard.LEFT ? -1 : 1) + 47) % 47;
				if (main.autoPlay){
					main.setState(HokkaidoBox2d.TITLE_STATE);
				}else{
					end(); start();
				}
				break;
		}
	}

	public function wheelHandler(event:MouseEvent):void{
		if (main.autoPlay && (!event.ctrlKey || !event.shiftKey)) return;

		main.prefIndex = (main.prefIndex + (event.delta < 0 ? 1 : -1) + 47) % 47;
		if (main.autoPlay){
			main.setState(HokkaidoBox2d.TITLE_STATE);
		} else {
			end(); start();
		}
	}

	private function startBox2dAnimation():void{
		addEventListener("enterFrame", enterFrameHandler);
		if (!main.autoPlay) return;

		// こう跳ねます
		var likeThis:LikeThis = new LikeThis();
		likeThis.alpha = 0;
		addChild(likeThis);

		Tweener.addTween(likeThis, {
			alpha: 1,
			delay: 5,
			time: 2,
			transition: 'easeInSine'
		});
		Tweener.addTween(this, {
			alpha: 0,
			delay: 8,
			time: 2,
			onComplete: function():void{
				if (main.prefIndex == 46 && !main.autoRepeat){
					main.setState(HokkaidoBox2d.INDEX_STATE);
				} else {
					main.prefIndex = (main.prefIndex + 1) % 47;
					main.setState(HokkaidoBox2d.TITLE_STATE);
				}
			}
		});
	}

	private const R:int = 30;

	// ナビゲーションボタンを表示
	private function addButtons():void{
		backButton = new Button(80, 30, 10, "BACK", 14);
		replayButton = new Button(80, 30, 10, "REPLAY", 14);
		nextButton = new Button(R, R, R);
		prevButton = new Button(R, R, R);

		backButton.y = replayButton.y = 6;
		backButton.x = 10; replayButton.x = 100;
		prevButton.x = 10; nextButton.x = HokkaidoBox2d.WIDTH - 40;
		prevButton.y = nextButton.y = (HokkaidoBox2d.HEIGHT - 30) / 2;

		var tri1:Sprite = createTriangle(R * .3), tri2:Sprite = createTriangle(R * .3);
		tri1.x = tri1.y = tri2.x = tri2.y = R / 2;
		tri2.rotation = 180;
		prevButton.addChild(tri1);
		nextButton.addChild(tri2);

		backButton.alpha = replayButton.alpha = prevButton.alpha = nextButton.alpha = .6;

		addChild(backButton);
		addChild(replayButton);
		addChild(prevButton);
		addChild(nextButton);
	}

	private function createTriangle(r:Number):Sprite{
		var s:Sprite = new Sprite();
		s.graphics.beginFill(0x6699cc);
		s.graphics.moveTo(-r, 0);
		s.graphics.lineTo(r / 2, r * Math.sqrt(3) / 2);
		s.graphics.lineTo(r / 2, -r * Math.sqrt(3) / 2);
		s.graphics.endFill();
		return s;
	}

	private function enterFrameHandler(event:Event):void{
		world.Step(1 / 36, 10);

		for (var b:b2Body = world.GetBodyList(); b; b = b.GetNext()) {
			var sprite:Sprite = b.GetUserData() as Sprite;
			if(!sprite) continue;
			sprite.x = b.GetWorldCenter().x * SCALE;
			sprite.y = b.GetWorldCenter().y * SCALE;
			sprite.rotation = b.GetAngle() * 180 / Math.PI;
		}
	}

	private function clickHandler(event:Event):void{
		if(event.target is Button){
			if (event.target == backButton){
				main.setState(HokkaidoBox2d.INDEX_STATE);
			} else if (event.target == replayButton){
				end(); start();
			} else if (event.target == nextButton){
				main.prefIndex = (main.prefIndex + 1) % 47;
				end(); start();
			} else if (event.target == prevButton){
				main.prefIndex = (main.prefIndex - 1 + 47) % 47;
				end(); start();
			}
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
		var zoom:Number = PrefBox2d[prefIndex]['zoom'];

		// 先に Sprite を作って横幅を調べる
		var cmin:Number = Infinity, cmax:Number = -Infinity;
		for each(var area:Object in PrefData[prefIndex]){
			for (var i:int = 0; i < area.c.length / 2; i++){
				if(cmin > area.c[i * 2]) cmin = area.c[i * 2];
				if(cmax < area.c[i * 2]) cmax = area.c[i * 2];
			}
		}
		var w:Number = (cmax - cmin) / SCALE * zoom;

		// 都道府県を作る
		var bodyDef:b2BodyDef = new b2BodyDef();
		bodyDef.position.Set((4.5 - w) / 2, 0.2);

		var prefSprites:Array = [];
		for each(area in PrefData[prefIndex]){
			// box2d 上に凸包を作成
			var body:b2Body = world.CreateBody(bodyDef);
			createBox2dConvex(body, area.c, prefIndex);

			// 表示するSprite を作成
			var center:b2Vec2 = body.GetLocalCenter();
			body.m_userData = HokkaidoBox2d.createAreaSprite(area.p, -center.x * SCALE, -center.y * SCALE, zoom);
			if (!main.autoPlay){
				body.m_userData.buttonMode = true;
				body.m_userData.addEventListener("mouseDown", mouseDownHandler);
			}
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
		shapeDef.density = PrefBox2d[prefIndex].d || 1;
		shapeDef.restitution = PrefBox2d[prefIndex].r || 0.7;
		shapeDef.friction = PrefBox2d[prefIndex].f || 0.2;
		var zoom:Number = PrefBox2d[prefIndex].zoom || 1.0;

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
		var prefName:String = PrefBox2d[prefIndex].name;
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

class Index extends Sprite implements IState{
	private var main:HokkaidoBox2d;
	private var firstTime:Boolean;
	private var timer:uint = 0;

	private const MARGIN:int = 10;
	private const BTN_X_COUNT:int = 8;
	private const BTN_Y_COUNT:int = 7;

	private const WIDTH:Number = HokkaidoBox2d.WIDTH;
	private const HEIGHT:Number = HokkaidoBox2d.HEIGHT;

	public function Index(_main:HokkaidoBox2d):void{
		main = _main;
		firstTime = true;
	}

	public function start():void{
		x = WIDTH / 2;
		y = HEIGHT / 2;

		// タイトル
		var textField:TextField = createTitleText();
		textField.x = - textField.width / 2;
		textField.y = - textField.height / 2;
		textField.alpha = 0;
		addChild(textField);
		Tweener.addTween(textField, {
			alpha: 1,
			time: firstTime ? 5 : 1,
			transition: 'easeInSine'
		});

		var first:Boolean = firstTime;
		timer = setTimeout(function():void{ timer = 0; showButtons(first); }, firstTime ? 4000 : 0);

		addEventListener("click", clickHandler);
		firstTime = false;
	}

	public function end():void{
		while(numChildren) removeChildAt(0);
		Tweener.removeAllTweens();
		if(timer != 0) clearTimeout(timer);
		removeEventListener("click", clickHandler);
	}

	public function keyHandler(event:KeyboardEvent):void{}
	public function wheelHandler(event:MouseEvent):void{}

	private function constrain(v:Number, min:Number, max:Number):Number{
		if (v < min) return min;
		if (v > max) return max;
		return v;
	}

	private function showButtons(firstTime:Boolean):void{
		var w:Number = (WIDTH  - MARGIN) / BTN_X_COUNT;
		var h:Number = (HEIGHT - MARGIN) / BTN_Y_COUNT;

		var btns:Array = []
		for (var i:int = 0; i < BTN_Y_COUNT; i++){
			for (var j:int = 0; j < BTN_X_COUNT; j++){
				var prefIndex:int = i * BTN_X_COUNT + j;
				if (prefIndex >= 47) break;

				var btn:Button = new IndexButton(w - 4, h - 4, 10, prefIndex);
				btn.x = (j - BTN_X_COUNT / 2) * w;
				btn.y = (i - BTN_Y_COUNT / 2 + (i > 2 ? 1 : 0)) * h;
				addChild(btn);

				btns.push({
					b: btn, 
					d: Math.sqrt(Math.pow(btn.x, 2) + Math.pow(btn.y, 2)) / (firstTime ? 6 : 20)
				});
			}
		}

		var count:int = 0;
		var v:Number = firstTime ? 20 : 10;
		timer = setTimeout(function():void{
			timer = 0;
			var flag:Boolean = true;
			for each(var btn:Object in btns){
				btn.b.alpha = constrain((count - btn.d) / v, 0, 1);
				if (btn.b.alpha != 1) flag = false;
			}
			count++;
			if (!flag){
				timer = setTimeout(arguments.callee, 10);
			}
		}, 0);
	}

	private function createTitleText():TextField{
		var largeSize:int = 38, smallSize:int = 32;
		var str:String = <>
			<font face="KozMinPro" size={smallSize}>どの</font>
			<font face="KozGoPro" size={largeSize}>都道府県</font>
			<font face="KozMinPro" size={smallSize}>を</font>
			<font face="KozGoPro" size={largeSize}>落</font>
			<font face="KozMinPro" size={smallSize}>としますか？</font>
			</>.toString();

		var fmt:TextFormat = new TextFormat();
		fmt.letterSpacing = -2;

		var textField:EmbedTextField = new EmbedTextField();
		textField.defaultTextFormat = fmt;
		textField.text = str;
		textField.autoSize = "left";
		textField.htmlText = str;
		return textField;
	}

	private function clickHandler(event:Event):void{
		var btn:IndexButton = event.target as IndexButton;
		if (btn){
			main.autoPlay = false;
			main.prefIndex = btn.prefIndex;
			main.setState(HokkaidoBox2d.PLAYING_STATE);
		}
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

class IndexButton extends Button{
	private var label:TextField;

	private var _prefIndex:int;
	public function get prefIndex():int{
		return _prefIndex;
	}

	public function IndexButton(W:Number, H:Number, R:Number, __prefIndex:int):void{
		super(W, H, R);
		_prefIndex = __prefIndex;

		var preview:Sprite = new Sprite();
		var child:Sprite = HokkaidoBox2d.createAreaSprite(PrefData[prefIndex][0].p, 0, 0, 1.0);
		var rect:Rectangle = child.getRect(child);
		child.x = -rect.x;
		child.y = -rect.y;
		preview.addChild(child);

		var scale:Number = Math.min(width / preview.width, height / preview.height);
		preview.scaleX = preview.scaleY = scale * .8;
		preview.x = (width - preview.width) / 2;
		preview.y = (height - preview.height) / 2;
		addChild(preview);

		label = new EmbedTextField();
		label.width = W;
		label.autoSize = "center";
		label.htmlText = '<font face="KozGoPro" size="11" color="#336699">' + PrefBox2d[prefIndex].name + '</font>';
		label.y = (H - label.height) / 2;
		label.visible = false;
		label.filters = [new GlowFilter(0xffffff, 1, 3, 3)];
		addChild(label);
	}

	protected override function buttonRollOver(event:Event):void{
		super.buttonRollOver(event);
		label.visible = true;
	}

	protected override function buttonRollOut(event:Event):void{
		super.buttonRollOut(event);
		label.visible = false;
	}
}

