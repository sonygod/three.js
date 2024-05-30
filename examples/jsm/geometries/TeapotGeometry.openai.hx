import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Path;
import haxe.io.StringInput;
import haxe.io.StringOutput;

class TeapotGeometry extends haxe.io.Bytes {
	
	public static inline var DEFAULT_SIZE:Int = 50;
	public static inline var DEFAULT_SEGMENTS:Int = 10;
	public static inline var DEFAULT_BOTTOM:Bool = true;
	public static inline var DEFAULT_LID:Bool = true;
	public static inline var DEFAULT_BODY:Bool = true;
	public static inline var DEFAULT_FIT_LID:Bool = true;
	public static inline var DEFAULT_BLINN:Bool = true;

	public function new(size:Int = DEFAULT_SIZE, segments:Int = DEFAULT_SEGMENTS, bottom:Bool = DEFAULT_BOTTOM, lid:Bool = DEFAULT_LID, body:Bool = DEFAULT_BODY, fitLid:Bool = DEFAULT_FIT_LID, blinn:Bool = DEFAULT_BLINN) {
		super();
		// Tessellation parameters
		// ...
		// Bezier spline patches
		// ...
		// Vertices
		// ...
	}
}