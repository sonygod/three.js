import haxe.three.BufferGeometry;
import haxe.three.BufferAttribute;
import haxe.three.ExtrasShape;
import haxe.three.ExtrasShapeUtils;
import haxe.three.Vector2;

class ShapeGeometry extends BufferGeometry {
	
	public var shapes:ExtrasShape;
	public var curveSegments:Int;

	public function new(shapes:ExtrasShape = new ExtrasShape([new Vector2(0, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)]), curveSegments:Int = 12) {
		super();

		this.type = "ShapeGeometry";

		this.parameters = {
			"shapes": shapes,
			"curveSegments": curveSegments
		};

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		var groupStart:Int = 0;
		var groupCount:Int = 0;

		if (Array.isArray(shapes) == false) {
			addShape(shapes);
		} else {
			for (i in 0...shapes.length) {
				addShape(shapes[i]);

				this.addGroup(groupStart, groupCount, i);

				groupStart += groupCount;
				groupCount = 0;
			}
		}

		this.setIndex(indices);
		this.setAttribute("position", new BufferAttribute(vertices, 3));
		this.setAttribute("normal", new BufferAttribute(normals, 3));
		this.setAttribute("uv", new BufferAttribute(uvs, 2));

		function addShape(shape:ExtrasShape) {
			var indexOffset:Int = vertices.length / 3;
			var points = shape.extractPoints(curveSegments);
			var shapeVertices:Array<Vector2> = points.shape;
			var shapeHoles:Array<Array<Vector2>> = points.holes;

			if (ExtrasShapeUtils.isClockWise(shapeVertices) == false) {
				shapeVertices = shapeVertices.reverse();
			}

			for (j in 0...shapeHoles.length) {
				var shapeHole = shapeHoles[j];

				if (ExtrasShapeUtils.isClockWise(shapeHole) == true) {
					shapeHoles[j] = shapeHole.reverse();
				}
			}

			var faces = ExtrasShapeUtils.triangulateShape(shapeVertices, shapeHoles);

			for (j in 0...shapeHoles.length) {
				var shapeHole = shapeHoles[j];
				shapeVertices = shapeVertices.concat(shapeHole);
			}

			for (j in 0...shapeVertices.length) {
				var vertex = shapeVertices[j];

				vertices.push(vertex.x, vertex.y, 0);
				normals.push(0, 0, 1);
				uvs.push(vertex.x, vertex.y);
			}

			for (j in 0...faces.length) {
				var face = faces[j];

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

		this.parameters = source.parameters;

		return this;
	}
	
	public function toJSON():Dynamic {
		var data:Dynamic = super.toJSON();

		data.shapes = [];

		if (Array.isArray(shapes)) {
			for (i in 0...shapes.length) {
				var shape = shapes[i];

				data.shapes.push(shape.uuid);
			}
		} else {
			data.shapes.push(shapes.uuid);
		}

		return data;
	}

	public static function fromJSON(data:Dynamic, shapes:Vector<ExtrasShape>):ShapeGeometry {
		var geometryShapes:Array<ExtrasShape> = [];

		for (j in 0...data.shapes.length) {
			var shape = shapes[data.shapes[j]];

			geometryShapes.push(shape);
		}

		return new ShapeGeometry(geometryShapes, data.curveSegments);
	}
}