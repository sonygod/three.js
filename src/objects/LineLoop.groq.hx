package three.objects;

import three.objects.Line;

class LineLoop extends Line {

	public var isLineLoop:Bool = true;

	public var type:String = 'LineLoop';

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);
	}

}