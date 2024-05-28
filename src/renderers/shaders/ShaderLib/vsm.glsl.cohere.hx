package openfl._internal.formats.swf.filters;

class DropShadowFilter extends GlowFilter
{
	public function new(distance:Float, angle:Float, color:Int, alpha:Float, blurX:Float, blurY:Float, strength:Float, quality:Int, inner:Bool, knockout:Bool, hideObject:Bool)
	{
		super(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject);
	}

	override public function get_type():String
	{
		return "DropShadow";
	}
}