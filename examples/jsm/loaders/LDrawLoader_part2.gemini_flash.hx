package ;

import three.LineSegments;
import three.Geometry;
import three.Material;

class ConditionalLineSegments extends LineSegments {

	public function new(geometry:Geometry, material:Material) {

		super(geometry, material);
		this.isConditionalLine = true;

	}

}