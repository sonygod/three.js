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

		// buffers

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		// helper variables

		var groupStart:Int = 0;
		var groupCount:Int = 0;

		// allow single and array values for "shapes" parameter

		if (Type.typeof(shapes) != TClass(Array)) {

			addShape(shapes);

		} else {

			for (i in 0...cast(shapes, Array).length) {

				addShape(cast(shapes, Array)[i]);

				this.addGroup(groupStart, groupCount, i); // enables MultiMaterial support

				groupStart += groupCount;
				groupCount = 0;

			}

		}

		// build geometry

		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));


		// helper functions

		function addShape(shape:Dynamic) {

			var indexOffset:Int = vertices.length / 3;
			var points:Dynamic = shape.extractPoints(curveSegments);

			var shapeVertices:Array<Vector2> = cast(points.shape, Array);
			var shapeHoles:Array<Array<Vector2>> = cast(points.holes, Array);

			// check direction of vertices

			if (ShapeUtils.isClockWise(shapeVertices) == false) {

				shapeVertices = shapeVertices.reverse();

			}

			for (i in 0...shapeHoles.length) {

				var shapeHole:Array<Vector2> = shapeHoles[i];

				if (ShapeUtils.isClockWise(shapeHole) == true) {

					shapeHoles[i] = shapeHole.reverse();

				}

			}

			var faces:Array<Array<Int>> = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

			// join vertices of inner and outer paths to a single array

			for (i in 0...shapeHoles.length) {

				var shapeHole:Array<Vector2> = shapeHoles[i];
				shapeVertices = shapeVertices.concat(shapeHole);

			}

			// vertices, normals, uvs

			for (i in 0...shapeVertices.length) {

				var vertex:Vector2 = shapeVertices[i];

				vertices.push(vertex.x, vertex.y, 0);
				normals.push(0, 0, 1);
				uvs.push(vertex.x, vertex.y); // world uvs

			}

			// indices

			for (i in 0...faces.length) {

				var face:Array<Int> = faces[i];

				var a:Int = face[0] + indexOffset;
				var b:Int = face[1] + indexOffset;
				var c:Int = face[2] + indexOffset;

				indices.push(a, b, c);
				groupCount += 3;

			}

		}

	}

	public function copy(source:ShapeGeometry):ShapeGeometry {

		super.copy(source);

		this.parameters = cast(source.parameters, Dynamic);

		return this;

	}

	public function toJSON():Dynamic {

		var data:Dynamic = super.toJSON();

		var shapes:Dynamic = this.parameters.shapes;

		return toJSON(shapes, data);

	}

	public static function fromJSON(data:Dynamic, shapes:Dynamic):ShapeGeometry {

		var geometryShapes:Array<Dynamic> = [];

		for (j in 0...cast(data.shapes, Array).length) {

			var shape:Dynamic = shapes[cast(data.shapes, Array)[j]];

			geometryShapes.push(shape);

		}

		return new ShapeGeometry(geometryShapes, cast(data.curveSegments, Int));

	}

}

function toJSON(shapes:Dynamic, data:Dynamic):Dynamic {

	data.shapes = [];

	if (Type.typeof(shapes) == TClass(Array)) {

		for (i in 0...cast(shapes, Array).length) {

			var shape:Dynamic = cast(shapes, Array)[i];

			data.shapes.push(shape.uuid);

		}

	} else {

		data.shapes.push(shapes.uuid);

	}

	return data;

}