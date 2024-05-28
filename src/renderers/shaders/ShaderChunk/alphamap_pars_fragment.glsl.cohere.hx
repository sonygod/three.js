import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.utils.Assets;
import openfl.utils.ByteArray;

class AlphaMap {
	public static var code:String = '#ifdef USE_ALPHAMAP' + '\n\t' +
		'uniform sampler2D alphaMap;' + '\n' +
		'#endif';
}