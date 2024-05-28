package;

import Line from Line.hx;

class LineLoop extends Line {
	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);
		this.isLineLoop = true;
		this.type = "LineLoop";
	}
}