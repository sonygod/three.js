package ;

import kha.graphics3d.Geometry;
import kha.graphics3d.Material;

class LineLoop extends Line {

	public function new( geometry:Geometry, material:Material ) {

		super( geometry, material );

		this.isLineLoop = true;

		this.type = 'LineLoop';

	}

}