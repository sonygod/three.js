import Line from "./Line.hx";

class LineLoop extends Line {

	public var isLineLoop:Bool = true;
	public var type:String = "LineLoop";

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);
	}
}

class LineLoop {
	public static function get():LineLoop {
		return new LineLoop();
	}
}