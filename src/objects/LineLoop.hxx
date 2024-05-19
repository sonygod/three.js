import three.js.src.objects.Line;

class LineLoop extends Line {

	public function new(geometry:Geometry, material:Material) {

		super(geometry, material);

		this.isLineLoop = true;

		this.type = 'LineLoop';

	}

}

typedef LineLoop_three_js_src_objects_LineLoop = LineLoop;