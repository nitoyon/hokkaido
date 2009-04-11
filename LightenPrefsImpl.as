import mx.core.*;
import mx.utils.ObjectUtil;
import flash.utils.setTimeout;

private var areas:Array;
private var currentPref:int;
private var currentArea:int;
private var cmf:ColorMatrixFilter = new ColorMatrixFilter([
	.7,  0,  0,  0,  0,
	 0, .7,  0,  0,  0,
	 0,  0, .7,  0,  0,
	 0,  0,  0,  1,  0,
]);

private var outputPref:Array;

// Application initialize
private function applicationCompleteHandler(e:Event):void{
	outputPref = ObjectUtil.copy(Prefs) as Array;

	// init list data
	initListData();

	// event handler
	ptSlider.addEventListener(Event.CHANGE, sliderChangeHandler);
	cvSlider.addEventListener(Event.CHANGE, sliderChangeHandler);
}

private function initListData():void{
	var arr:Array = [];

	var i:int = 0;
	setTimeout(function():void{
		var j:int = 0;
		for each (var area:Object in Prefs[i]){
			var pc:int = area.p.length;
			var vc:int = area.c.length;
			arr.push({
				name: PrefBox2d[i]['name'],
				pref: i,
				count: j,
				pt: (pc >= 15 ? 70 - pc / 30 : 100),
				convex: (vc > 15 ? 80 - vc / 2.5 : 100),
				pts: pc,
				convexs: vc
			});

			if (arr[j].pt != 100){
				outputPref[i][j].p = lighten(arr[j].pt, area.p)
			}
			if (arr[j].convex != 100){
				outputPref[i][j].c = lighten(arr[j].convex, area.c)
			}

			j++;
		}
		i++;

		if(i < 47){
			setTimeout(arguments.callee, 10);
		}else{
			list.dataProvider = arr;
		}
	}, 10);
}

// List pref change handler
private function prefsChangeHandler(event:Event):void{
	if (list.selectedIndex < 0){
		areas = null;
		return;
	}

	currentPref = list.selectedItem.pref;
	currentArea = list.selectedItem.count;
	ptSlider.value = list.selectedItem.pt;
	cvSlider.value = list.selectedItem.convex;

	areas = Prefs[currentPref];
	drawCanvas(canvas1, areas);
	sliderChangeHandler(null);
}

private function sliderChangeHandler(event:Event):void{
	var area:Object = Prefs[currentPref][currentArea];

	if (!event || event.target == ptSlider){
		outputPref[currentPref][currentArea].p = lighten(ptSlider.value, area.p)
		list.selectedItem.pt = ptSlider.value;
	}
	if (!event || event.target == cvSlider){
		outputPref[currentPref][currentArea].c = lighten(cvSlider.value, area.c)
		list.selectedItem.convex = cvSlider.value;
	}

	drawCanvas(canvas2, outputPref[currentPref]);
	list.invalidateList();
}

// draw canvas
private function drawCanvas(canvas:UIComponent, areas:Array):void{
	while(canvas.numChildren) canvas.removeChildAt(0);
	if(areas == null) return;

	var prefParent:UIComponent = new UIComponent();
	var prefSprite:Sprite = new Sprite();

	// each area
	for (var i:int = 0; i < areas.length; i++){
		// draw convex
		var convex:Array = areas[i].c;
		var cvSprite:Sprite = new Sprite();
		cvSprite.graphics.lineStyle(0, 0x6699cc);
		cvSprite.graphics.moveTo(convex[0], convex[1]);
		for(var j:int = 0; j < convex.length / 2; j++){
			cvSprite.graphics.lineTo(convex[j * 2], convex[j * 2 + 1]);
		}
		cvSprite.graphics.lineTo(convex[0], convex[1]);
		cvSprite.graphics.endFill();
		prefSprite.addChild(cvSprite);

		// draw pt
		var pt:Array = areas[i].p;
		var sprite:Sprite = PrefUtil.createAreaSprite(pt, 0, 0, 1);
		if(i == currentArea) sprite.filters = [cmf];
		prefSprite.addChild(sprite);
	}

	prefParent.addChild(prefSprite);
	canvas.addChild(prefParent);

	var ratio:Number = Math.min(canvas.width / prefSprite.width, canvas.height / prefSprite.height);
	prefSprite.scaleX = prefSprite.scaleY = ratio;
}

private function lighten(ratio:Number, points:Array):Array{
	var pt:Array = ObjectUtil.copy(points) as Array;

	var size:int = pt.length / 2;
	var count:int = size * (100.0 - ratio) / 100.0;

	for(var l:int = 0; l < count; l++){
		var min:Object = {len: Infinity, j: -1};
		for(var j:int = 0; j < pt.length / 2 - 1; j++){
			var len:Number = Math.pow(pt[j * 2] - pt[j * 2 + 2], 2) + Math.pow(pt[j * 2 + 1] - pt[j * 2 + 3], 2);
			if(!isNaN(len) && min.len > len){
				min = {len: len, j: j,
					x: (pt[j * 2 + 0] + pt[j * 2 + 2]) / 2,
					y: (pt[j * 2 + 1] + pt[j * 2 + 3]) / 2
				};
			}
		}

		if(min.j == -1) break;
		pt.splice(min.j * 2, 4, min.x, min.y);
	}

	return pt;
}

private function save():void{
	var bytes:ByteArray = new ByteArray();
	bytes.writeObject(outputPref);
	bytes.compress();

	var ref:FileReference = new FileReference();
	ref.save(bytes, "out.bin");
}