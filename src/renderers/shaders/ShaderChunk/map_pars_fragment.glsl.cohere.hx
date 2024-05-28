import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.filters.BitmapFilter;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class TileMap extends Sprite {
	public var tilesheet:Tilesheet;
	public var map:Array<Int>;
	public var tileSize:Int;
	public var tileScale:Number;
	public var tileColor:Int;
	public var tileColorEnabled:Bool;
	public var tileColorTransform:ColorTransform;
	public var tileColorTransformEnabled:Bool;
	public var tileAlpha:Float;
	public var tileAlphaEnabled:Bool;
	public var tileBlendMode:String;
	public var tileBlendModeEnabled:Bool;
	public var tileFilter:BitmapFilter;
	public var tileFilterEnabled:Bool;
	public var tileGlow:GlowFilter;
	public var tileGlowEnabled:Bool;
	public var tileGlowColor:Int;
	public var tileGlowStrength:Float;
	public var tileGlowQuality:Int;
	public var tileGlowInnerStrength:Float;
	public var tileGlowKnockout:Bool;
	public var tileGlowBlurX:Float;
	public var tileGlowBlurY:Float;
	public var tileGlowDistance:Float;
	public var tileGlowAngle:Float;
	public var tileGlowColorTransform:ColorTransform;
	public var tileGlowColorTransformEnabled:Bool;
	public var tileGlowBlendMode:String;
	public var tileGlowBlendModeEnabled:Bool;
	public var tileMatrix:Matrix;
	public var tileMatrixEnabled:Bool;
	public var tileOffset:Point;
	public var tileOffsetEnabled:Bool;
	public var tileRect:Rectangle;
	public var tileRectEnabled:Bool;
	public var tileOrigin:Point;
	public var tileOriginEnabled:Bool;
	public var tileClip:Bool;
	public var tileClipEnabled:Bool;

	public function new(tilesheet:Tilesheet, map:Array<Int>, tileSize:Int, tileScale:Number = 1.0) {
		super();

		this.tilesheet = tilesheet;
		this.map = map;
		this.tileSize = tileSize;
		this.tileScale = tileScale;

		this.addEventListener(Event.ADDED_TO_STAGE, init);
	}

	public function init(e:Event):Void {
		var tile:DisplayObject;
		var x:Int;
		var y:Int;
		var i:Int;
		var j:Int;

		for (i = 0; i < map.length; i++) {
			x = (i % (map[0].length)) * tileSize;
			y = (i / (map[0].length)) * tileSize;

			tile = tilesheet.getTile(map[i], tileScale);
			tile.x = x;
			tile.y = y;

			this.addChild(tile);
		}
	}
}