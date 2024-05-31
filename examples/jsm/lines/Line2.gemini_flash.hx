package ;

import three.ThreeImports.*;
import three.core.Object3D;

class Line2 extends LineSegments2 {

	public var isLine2 : Bool;

	public function new( geometry : LineGeometry = new LineGeometry(), material : LineMaterial = new LineMaterial( { color: Math.random() * 0xffffff } ) ) {

		super( geometry, material );

		this.isLine2 = true;

		this.type = 'Line2';

	}

}