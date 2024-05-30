import three.js.examples.jsm.geometries.BufferGeometry;
import three.js.examples.jsm.core.BufferAttribute;

class BoxLineGeometry extends BufferGeometry {

	public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {

		super();

		widthSegments = Std.int(widthSegments);
		heightSegments = Std.int(heightSegments);
		depthSegments = Std.int(depthSegments);

		var widthHalf = width / 2;
		var heightHalf = height / 2;
		var depthHalf = depth / 2;

		var segmentWidth = width / widthSegments;
		var segmentHeight = height / heightSegments;
		var segmentDepth = depth / depthSegments;

		var vertices = [];

		var x = - widthHalf;
		var y = - heightHalf;
		var z = - depthHalf;

		for (i in 0...widthSegments + 1) {

			vertices.push(x, - heightHalf, - depthHalf, x, heightHalf, - depthHalf);
			vertices.push(x, heightHalf, - depthHalf, x, heightHalf, depthHalf);
			vertices.push(x, heightHalf, depthHalf, x, - heightHalf, depthHalf);
			vertices.push(x, - heightHalf, depthHalf, x, - heightHalf, - depthHalf);

			x += segmentWidth;

		}

		for (i in 0...heightSegments + 1) {

			vertices.push(- widthHalf, y, - depthHalf, widthHalf, y, - depthHalf);
			vertices.push(widthHalf, y, - depthHalf, widthHalf, y, depthHalf);
			vertices.push(widthHalf, y, depthHalf, - widthHalf, y, depthHalf);
			vertices.push(- widthHalf, y, depthHalf, - widthHalf, y, - depthHalf);

			y += segmentHeight;

		}

		for (i in 0...depthSegments + 1) {

			vertices.push(- widthHalf, - heightHalf, z, - widthHalf, heightHalf, z);
			vertices.push(- widthHalf, heightHalf, z, widthHalf, heightHalf, z);
			vertices.push(widthHalf, heightHalf, z, widthHalf, - heightHalf, z);
			vertices.push(widthHalf, - heightHalf, z, - widthHalf, - heightHalf, z);

			z += segmentDepth;

		}

		this.setAttribute('position', new BufferAttribute(vertices, 3));

	}

}

export(BoxLineGeometry);