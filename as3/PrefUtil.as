package{
import flash.display.*;

public class PrefUtil{
	// 都道府県番号とエリア番号から Sprite を作る
	static public function createAreaSprite(points:Array, centerX:Number, centerY:Number, zoom:Number):Sprite{
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
}
}
