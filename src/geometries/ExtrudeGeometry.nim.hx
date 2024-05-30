import three.js.src.core.BufferGeometry;
import three.js.src.core.BufferAttribute;
import three.js.src.extras.curves.Curves;
import three.js.src.math.Vector2;
import three.js.src.math.Vector3;
import three.js.src.extras.core.Shape;
import three.js.src.extras.ShapeUtils;

class ExtrudeGeometry extends BufferGeometry {

	public var type:String = 'ExtrudeGeometry';
	public var parameters:Dynamic;

	public function new(shapes:Array<Shape> = [new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], options:Dynamic = {}) {
		super();

		this.parameters = {
			shapes: shapes,
			options: options
		};

		shapes = (shapes is Array) ? shapes : [shapes];

		var scope = this;
		var verticesArray:Array<Float> = [];
		var uvArray:Array<Float> = [];

		for (i in 0...shapes.length) {
			var shape = shapes[i];
			addShape(shape);
		}

		this.setAttribute('position', new BufferAttribute(verticesArray, 3));
		this.setAttribute('uv', new BufferAttribute(uvArray, 2));

		this.computeVertexNormals();

		function addShape(shape:Shape) {
			var placeholder:Array<Float> = [];

			var curveSegments = (options.curveSegments != null) ? options.curveSegments : 12;
			var steps = (options.steps != null) ? options.steps : 1;
			var depth = (options.depth != null) ? options.depth : 1;

			var bevelEnabled = (options.bevelEnabled != null) ? options.bevelEnabled : true;
			var bevelThickness = (options.bevelThickness != null) ? options.bevelThickness : 0.2;
			var bevelSize = (options.bevelSize != null) ? options.bevelSize : bevelThickness - 0.1;
			var bevelOffset = (options.bevelOffset != null) ? options.bevelOffset : 0;
			var bevelSegments = (options.bevelSegments != null) ? options.bevelSegments : 3;

			var extrudePath = options.extrudePath;

			var uvgen = (options.UVGenerator != null) ? options.UVGenerator : WorldUVGenerator;

			var extrudePts, extrudeByPath = false;
			var splineTube, binormal, normal, position2;

			if (extrudePath != null) {
				extrudePts = extrudePath.getSpacedPoints(steps);

				extrudeByPath = true;
				bevelEnabled = false; // bevels not supported for path extrusion

				splineTube = extrudePath.computeFrenetFrames(steps, false);

				binormal = new Vector3();
				normal = new Vector3();
				position2 = new Vector3();
			}

			if (!bevelEnabled) {
				bevelSegments = 0;
				bevelThickness = 0;
				bevelSize = 0;
				bevelOffset = 0;
			}

			var shapePoints = shape.extractPoints(curveSegments);

			var vertices = shapePoints.shape;
			var holes = shapePoints.holes;

			var reverse = !ShapeUtils.isClockWise(vertices);

			if (reverse) {
				vertices = vertices.reverse();

				for (h in 0...holes.length) {
					var ahole = holes[h];

					if (ShapeUtils.isClockWise(ahole)) {
						holes[h] = ahole.reverse();
					}
				}
			}

			var faces = ShapeUtils.triangulateShape(vertices, holes);

			// ... rest of the code ...
		}
	}

	public function copy(source:ExtrudeGeometry):ExtrudeGeometry {
		super.copy(source);

		this.parameters = Reflect.copy(source.parameters);

		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();

		var shapes = this.parameters.shapes;
		var options = this.parameters.options;

		return toJSON(shapes, options, data);
	}

	public static function fromJSON(data:Dynamic, shapes:Array<Shape>):ExtrudeGeometry {
		var geometryShapes:Array<Shape> = [];

		for (j in 0...data.shapes.length) {
			var shape = shapes[data.shapes[j]];

			geometryShapes.push(shape);
		}

		var extrudePath = data.options.extrudePath;

		if (extrudePath != null) {
			data.options.extrudePath = new Curves[extrudePath.type]().fromJSON(extrudePath);
		}

		return new ExtrudeGeometry(geometryShapes, data.options);
	}
}

class WorldUVGenerator {

	public static function generateTopUV(geometry:ExtrudeGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int):Array<Vector2> {
		var a_x = vertices[indexA * 3];
		var a_y = vertices[indexA * 3 + 1];
		var b_x = vertices[indexB * 3];
		var b_y = vertices[indexB * 3 + 1];
		var c_x = vertices[indexC * 3];
		var c_y = vertices[indexC * 3 + 1];

		return [
			new Vector2(a_x, a_y),
			new Vector2(b_x, b_y),
			new Vector2(c_x, c_y)
		];
	}

	public static function generateSideWallUV(geometry:ExtrudeGeometry, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int, indexD:Int):Array<Vector2> {
		var a_x = vertices[indexA * 3];
		var a_y = vertices[indexA * 3 + 1];
		var a_z = vertices[indexA * 3 + 2];
		var b_x = vertices[indexB * 3];
		var b_y = vertices[indexB * 3 + 1];
		var b_z = vertices[indexB * 3 + 2];
		var c_x = vertices[indexC * 3];
		var c_y = vertices[indexC * 3 + 1];
		var c_z = vertices[indexC * 3 + 2];
		var d_x = vertices[indexD * 3];
		var d_y = vertices[indexD * 3 + 1];
		var d_z = vertices[indexD * 3 + 2];

		if (Math.abs(a_y - b_y) < Math.abs(a_x - b_x)) {
			return [
				new Vector2(a_x, 1 - a_z),
				new Vector2(b_x, 1 - b_z),
				new Vector2(c_x, 1 - c_z),
				new Vector2(d_x, 1 - d_z)
			];
		} else {
			return [
				new Vector2(a_y, 1 - a_z),
				new Vector2(b_y, 1 - b_z),
				new Vector2(c_y, 1 - c_z),
				new Vector2(d_y, 1 - d_z)
			];
		}
	}
}

function toJSON(shapes:Array<Shape>, options:Dynamic, data:Dynamic):Dynamic {
	data.shapes = [];

	if (shapes is Array) {
		for (i in 0...shapes.length) {
			var shape = shapes[i];

			data.shapes.push(shape.uuid);
		}
	} else {
		data.shapes.push(shapes.uuid);
	}

	data.options = Reflect.copy(options);

	if (options.extrudePath != null) data.options.extrudePath = options.extrudePath.toJSON();

	return data;
}