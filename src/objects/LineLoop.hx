package three.objects;

import three.objects.Line;

class LineLoop extends Line {

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);
		this.isLineLoop = true;
		this.type = 'LineLoop';
	}

}