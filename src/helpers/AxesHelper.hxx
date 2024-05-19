import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class AxesHelper extends LineSegments {

	public function new(size:Float = 1) {

		var vertices:Array<Float> = [
			0, 0, 0,	size, 0, 0,
			0, 0, 0,	0, size, 0,
			0, 0, 0,	0, 0, size
		];

		var colors:Array<Float> = [
			1, 0, 0,	1, 0.6, 0,
			0, 1, 0,	0.6, 1, 0,
			0, 0, 1,	0, 0.6, 1
		];

		var geometry = new BufferGeometry();
		geometry.setAttribute( 'position', new BufferAttribute( vertices, 3 ) );
		geometry.setAttribute( 'color', new BufferAttribute( colors, 3 ) );

		var material = new LineBasicMaterial( { vertexColors: true, toneMapped: false } );

		super(geometry, material);

		this.type = 'AxesHelper';

	}

	public function setColors(xAxisColor:Color, yAxisColor:Color, zAxisColor:Color):AxesHelper {

		var array = this.geometry.attributes.color.array;

		xAxisColor.toArray(array, 0);
		xAxisColor.toArray(array, 3);

		yAxisColor.toArray(array, 6);
		yAxisColor.toArray(array, 9);

		zAxisColor.toArray(array, 12);
		zAxisColor.toArray(array, 15);

		this.geometry.attributes.color.needsUpdate = true;

		return this;

	}

	public function dispose():Void {

		this.geometry.dispose();
		this.material.dispose();

	}

}