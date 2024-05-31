import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.extras.core.Shape;
import three.extras.ShapeUtils;
import three.math.Vector2;

class ShapeGeometry extends BufferGeometry {

	public var shapes:Dynamic;
	public var curveSegments:Int;

	public function new(shapes:Dynamic = new Shape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)]), curveSegments:Int = 12) {
		super();
		this.type = "ShapeGeometry";
		this.parameters = {
			"shapes": shapes,
			"curveSegments": curveSegments
		};

		this.shapes = shapes;
		this.curveSegments = curveSegments;

		// buffers
		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		// helper variables
		var groupStart = 0;
		var groupCount = 0;

		// allow single and array values for "shapes" parameter
		if (Std.is(shapes, Array)) {
			for (i in 0...cast(shapes, Array<Dynamic>).length) {
				addShape(cast(shapes, Array<Dynamic>)[i]);
				this.addGroup(groupStart, groupCount, i); // enables MultiMaterial support
				groupStart += groupCount;
				groupCount = 0;
			}
		} else {
			addShape(shapes);
		}

		// build geometry
		this.setIndex(new IntBufferAttribute(indices, 1));
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

		// helper functions
		function addShape(shape:Shape) {
			var indexOffset = vertices.length / 3;
			var points = shape.extractPoints(curveSegments);

			var shapeVertices = points.shape;
			var shapeHoles = points.holes;

			// check direction of vertices
			if (!ShapeUtils.isClockWise(shapeVertices)) {
				shapeVertices = shapeVertices.reverse();
			}

			for (i in 0...shapeHoles.length) {
				var shapeHole = shapeHoles[i];
				if (ShapeUtils.isClockWise(shapeHole)) {
					shapeHoles[i] = shapeHole.reverse();
				}
			}

			var faces = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

			// join vertices of inner and outer paths to a single array
			for (i in 0...shapeHoles.length) {
				var shapeHole = shapeHoles[i];
				shapeVertices = shapeVertices.concat(shapeHole);
			}

			// vertices, normals, uvs
			for (i in 0...shapeVertices.length) {
				var vertex = shapeVertices[i];
				vertices.push(vertex.x, vertex.y, 0);
				normals.push(0, 0, 1);
				uvs.push(vertex.x, vertex.y); // world uvs
			}

			// indices
			for (i in 0...faces.length) {
				var face = faces[i];
				var a = face[0] + indexOffset;
				var b = face[1] + indexOffset;
				var c = face[2] + indexOffset;
				indices.push(a, b, c);
				groupCount += 3;
			}
		}
	}

	public function copy(source:ShapeGeometry):ShapeGeometry {
		super.copy(source);
		this.parameters = {
			"shapes": source.shapes,
			"curveSegments": source.curveSegments
		};
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		var shapes = this.shapes;
		return toJSON(shapes, data);
	}

	public static function fromJSON(data:Dynamic, shapes:Dynamic):ShapeGeometry {
		var geometryShapes:Array<Dynamic> = [];
		for (j in 0...cast(data.shapes, Array<Dynamic>).length) {
			var shape = shapes[cast(data.shapes, Array<Dynamic>)[j]];
			geometryShapes.push(shape);
		}
		return new ShapeGeometry(geometryShapes, cast(data.curveSegments, Int));
	}
}

function toJSON(shapes:Dynamic, data:Dynamic):Dynamic {
	data.shapes = [];
	if (Std.is(shapes, Array)) {
		for (i in 0...cast(shapes, Array<Dynamic>).length) {
			var shape = cast(shapes, Array<Dynamic>)[i];
			data.shapes.push(shape.uuid);
		}
	} else {
		data.shapes.push(shapes.uuid);
	}
	return data;
}

class IntBufferAttribute extends Float32BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		var floatArray:Array<Float> = [];
		for (i in array) floatArray.push(cast(array[i], Float));
		super(floatArray, itemSize, normalized);
	}
}