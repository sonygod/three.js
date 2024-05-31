import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;
import three.extras.core.Shape;
import three.extras.ShapeUtils;

class ExtrudeGeometry extends BufferGeometry {

	public var parameters: {
		shapes: Array<Shape>;
		options: {
			curveSegments: Int;
			steps: Int;
			depth: Float;
			bevelEnabled: Bool;
			bevelThickness: Float;
			bevelSize: Float;
			bevelOffset: Float;
			bevelSegments: Int;
			extrudePath: Curves.Curve;
			UVGenerator: WorldUVGenerator;
		};
	};

	public function new(shapes: Array<Shape> = [new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], options: {
		curveSegments: Int;
		steps: Int;
		depth: Float;
		bevelEnabled: Bool;
		bevelThickness: Float;
		bevelSize: Float;
		bevelOffset: Float;
		bevelSegments: Int;
		extrudePath: Curves.Curve;
		UVGenerator: WorldUVGenerator;
	} = {}) {
		super();
		this.type = "ExtrudeGeometry";
		this.parameters = {
			shapes: shapes,
			options: options
		};
		var verticesArray: Array<Float> = [];
		var uvArray: Array<Float> = [];
		for (i in 0...shapes.length) {
			addShape(shapes[i]);
		}
		this.setAttribute("position", new Float32BufferAttribute(verticesArray, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvArray, 2));
		this.computeVertexNormals();
	}

	private function addShape(shape: Shape) {
		var placeholder: Array<Float> = [];
		// options
		var curveSegments = this.parameters.options.curveSegments != null ? this.parameters.options.curveSegments : 12;
		var steps = this.parameters.options.steps != null ? this.parameters.options.steps : 1;
		var depth = this.parameters.options.depth != null ? this.parameters.options.depth : 1;
		var bevelEnabled = this.parameters.options.bevelEnabled != null ? this.parameters.options.bevelEnabled : true;
		var bevelThickness = this.parameters.options.bevelThickness != null ? this.parameters.options.bevelThickness : 0.2;
		var bevelSize = this.parameters.options.bevelSize != null ? this.parameters.options.bevelSize : bevelThickness - 0.1;
		var bevelOffset = this.parameters.options.bevelOffset != null ? this.parameters.options.bevelOffset : 0;
		var bevelSegments = this.parameters.options.bevelSegments != null ? this.parameters.options.bevelSegments : 3;
		var extrudePath = this.parameters.options.extrudePath;
		var uvgen = this.parameters.options.UVGenerator != null ? this.parameters.options.UVGenerator : WorldUVGenerator;
		//
		var extrudePts: Array<Vector3>;
		var extrudeByPath = false;
		var splineTube: {
			tangents: Array<Vector3>;
			normals: Array<Vector3>;
			binormals: Array<Vector3>;
		};
		var binormal: Vector3;
		var normal: Vector3;
		var position2: Vector3;
		if (extrudePath != null) {
			extrudePts = extrudePath.getSpacedPoints(steps);
			extrudeByPath = true;
			bevelEnabled = false;
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
		// Variables initialization
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
		// Vertices
		var contour = vertices;
		for (h in 0...holes.length) {
			var ahole = holes[h];
			vertices = vertices.concat(ahole);
		}
		function scalePt2(pt: Vector2, vec: Vector2, size: Float): Vector2 {
			return pt.clone().addScaledVector(vec, size);
		}
		var vlen = vertices.length;
		var flen = faces.length;
		// Find directions for point movement
		function getBevelVec(inPt: Vector2, inPrev: Vector2, inNext: Vector2): Vector2 {
			var v_trans_x: Float;
			var v_trans_y: Float;
			var shrink_by: Float;
			var v_prev_x = inPt.x - inPrev.x;
			var v_prev_y = inPt.y - inPrev.y;
			var v_next_x = inNext.x - inPt.x;
			var v_next_y = inNext.y - inPt.y;
			var v_prev_lensq = v_prev_x * v_prev_x + v_prev_y * v_prev_y;
			var collinear0 = v_prev_x * v_next_y - v_prev_y * v_next_x;
			if (Math.abs(collinear0) > Number.EPSILON) {
				var v_prev_len = Math.sqrt(v_prev_lensq);
				var v_next_len = Math.sqrt(v_next_x * v_next_x + v_next_y * v_next_y);
				var ptPrevShift_x = inPrev.x - v_prev_y / v_prev_len;
				var ptPrevShift_y = inPrev.y + v_prev_x / v_prev_len;
				var ptNextShift_x = inNext.x - v_next_y / v_next_len;
				var ptNextShift_y = inNext.y + v_next_x / v_next_len;
				var sf = ((ptNextShift_x - ptPrevShift_x) * v_next_y - (ptNextShift_y - ptPrevShift_y) * v_next_x) / (v_prev_x * v_next_y - v_prev_y * v_next_x);
				v_trans_x = ptPrevShift_x + v_prev_x * sf - inPt.x;
				v_trans_y = ptPrevShift_y + v_prev_y * sf - inPt.y;
				var v_trans_lensq = v_trans_x * v_trans_x + v_trans_y * v_trans_y;
				if (v_trans_lensq <= 2) {
					return new Vector2(v_trans_x, v_trans_y);
				} else {
					shrink_by = Math.sqrt(v_trans_lensq / 2);
				}
			} else {
				var direction_eq = false;
				if (v_prev_x > Number.EPSILON) {
					if (v_next_x > Number.EPSILON) {
						direction_eq = true;
					}
				} else {
					if (v_prev_x < -Number.EPSILON) {
						if (v_next_x < -Number.EPSILON) {
							direction_eq = true;
						}
					} else {
						if (Math.sign(v_prev_y) == Math.sign(v_next_y)) {
							direction_eq = true;
						}
					}
				}
				if (direction_eq) {
					v_trans_x = -v_prev_y;
					v_trans_y = v_prev_x;
					shrink_by = Math.sqrt(v_prev_lensq);
				} else {
					v_trans_x = v_prev_x;
					v_trans_y = v_prev_y;
					shrink_by = Math.sqrt(v_prev_lensq / 2);
				}
			}
			return new Vector2(v_trans_x / shrink_by, v_trans_y / shrink_by);
		}
		var contourMovements: Array<Vector2> = [];
		for (i in 0...contour.length) {
			var j = (i + contour.length - 1) % contour.length;
			var k = (i + 1) % contour.length;
			contourMovements[i] = getBevelVec(contour[i], contour[j], contour[k]);
		}
		var holesMovements: Array<Array<Vector2>> = [];
		var oneHoleMovements: Array<Vector2>;
		var verticesMovements = contourMovements.copy();
		for (h in 0...holes.length) {
			var ahole = holes[h];
			oneHoleMovements = [];
			for (i in 0...ahole.length) {
				var j = (i + ahole.length - 1) % ahole.length;
				var k = (i + 1) % ahole.length;
				oneHoleMovements[i] = getBevelVec(ahole[i], ahole[j], ahole[k]);
			}
			holesMovements.push(oneHoleMovements);
			verticesMovements = verticesMovements.concat(oneHoleMovements);
		}
		// Loop bevelSegments, 1 for the front, 1 for the back
		for (b in 0...bevelSegments) {
			var t = b / bevelSegments;
			var z = bevelThickness * Math.cos(t * Math.PI / 2);
			var bs = bevelSize * Math.sin(t * Math.PI / 2) + bevelOffset;
			// contract shape
			for (i in 0...contour.length) {
				var vert = scalePt2(contour[i], contourMovements[i], bs);
				v(vert.x, vert.y, -z);
			}
			// expand holes
			for (h in 0...holes.length) {
				var ahole = holes[h];
				oneHoleMovements = holesMovements[h];
				for (i in 0...ahole.length) {
					var vert = scalePt2(ahole[i], oneHoleMovements[i], bs);
					v(vert.x, vert.y, -z);
				}
			}
		}
		bs = bevelSize + bevelOffset;
		// Back facing vertices
		for (i in 0...vlen) {
			var vert = bevelEnabled ? scalePt2(vertices[i], verticesMovements[i], bs) : vertices[i];
			if (!extrudeByPath) {
				v(vert.x, vert.y, 0);
			} else {
				normal.copy(splineTube.normals[0]).multiplyScalar(vert.x);
				binormal.copy(splineTube.binormals[0]).multiplyScalar(vert.y);
				position2.copy(extrudePts[0]).add(normal).add(binormal);
				v(position2.x, position2.y, position2.z);
			}
		}
		// Add stepped vertices...
		// Including front facing vertices
		for (s in 1...(steps + 1)) {
			for (i in 0...vlen) {
				var vert = bevelEnabled ? scalePt2(vertices[i], verticesMovements[i], bs) : vertices[i];
				if (!extrudeByPath) {
					v(vert.x, vert.y, depth / steps * s);
				} else {
					normal.copy(splineTube.normals[s]).multiplyScalar(vert.x);
					binormal.copy(splineTube.binormals[s]).multiplyScalar(vert.y);
					position2.copy(extrudePts[s]).add(normal).add(binormal);
					v(position2.x, position2.y, position2.z);
				}
			}
		}
		// Add bevel segments planes
		for (b in (bevelSegments - 1)...-1) {
			var t = b / bevelSegments;
			var z = bevelThickness * Math.cos(t * Math.PI / 2);
			var bs = bevelSize * Math.sin(t * Math.PI / 2) + bevelOffset;
			// contract shape
			for (i in 0...contour.length) {
				var vert = scalePt2(contour[i], contourMovements[i], bs);
				v(vert.x, vert.y, depth + z);
			}
			// expand holes
			for (h in 0...holes.length) {
				var ahole = holes[h];
				oneHoleMovements = holesMovements[h];
				for (i in 0...ahole.length) {
					var vert = scalePt2(ahole[i], oneHoleMovements[i], bs);
					if (!extrudeByPath) {
						v(vert.x, vert.y, depth + z);
					} else {
						v(vert.x, vert.y + extrudePts[steps - 1].y, extrudePts[steps - 1].x + z);
					}
				}
			}
		}
		// Faces
		// Top and bottom faces
		buildLidFaces();
		// Sides faces
		buildSideFaces();
		// Internal functions
		function buildLidFaces() {
			var start = verticesArray.length / 3;
			if (bevelEnabled) {
				var layer = 0;
				var offset = vlen * layer;
				// Bottom faces
				for (i in 0...flen) {
					var face = faces[i];
					f3(face[2] + offset, face[1] + offset, face[0] + offset);
				}
				layer = steps + bevelSegments * 2;
				offset = vlen * layer;
				// Top faces
				for (i in 0...flen) {
					var face = faces[i];
					f3(face[0] + offset, face[1] + offset, face[2] + offset);
				}
			} else {
				// Bottom faces
				for (i in 0...flen) {
					var face = faces[i];
					f3(face[2], face[1], face[0]);
				}
				// Top faces
				for (i in 0...flen) {
					var face = faces[i];
					f3(face[0] + vlen * steps, face[1] + vlen * steps, face[2] + vlen * steps);
				}
			}
			this.addGroup(start, verticesArray.length / 3 - start, 0);
		}
		// Create faces for the z-sides of the shape
		function buildSideFaces() {
			var start = verticesArray.length / 3;
			var layeroffset = 0;
			sidewalls(contour, layeroffset);
			layeroffset += contour.length;
			for (h in 0...holes.length) {
				var ahole = holes[h];
				sidewalls(ahole, layeroffset);
				layeroffset += ahole.length;
			}
			this.addGroup(start, verticesArray.length / 3 - start, 1);
		}
		function sidewalls(contour: Array<Vector2>, layeroffset: Int) {
			var i = contour.length;
			while (i-- > 0) {
				var j = i;
				var k = (i - 1 + contour.length) % contour.length;
				for (s in 0...(steps + bevelSegments * 2)) {
					var slen1 = vlen * s;
					var slen2 = vlen * (s + 1);
					var a = layeroffset + j + slen1;
					var b = layeroffset + k + slen1;
					var c = layeroffset + k + slen2;
					var d = layeroffset + j + slen2;
					f4(a, b, c, d);
				}
			}
		}
		function v(x: Float, y: Float, z: Float) {
			placeholder.push(x);
			placeholder.push(y);
			placeholder.push(z);
		}
		function f3(a: Int, b: Int, c: Int) {
			addVertex(a);
			addVertex(b);
			addVertex(c);
			var nextIndex = verticesArray.length / 3;
			var uvs = uvgen.generateTopUV(this, verticesArray, nextIndex - 3, nextIndex - 2, nextIndex - 1);
			addUV(uvs[0]);
			addUV(uvs[1]);
			addUV(uvs[2]);
		}
		function f4(a: Int, b: Int, c: Int, d: Int) {
			addVertex(a);
			addVertex(b);
			addVertex(d);
			addVertex(b);
			addVertex(c);
			addVertex(d);
			var nextIndex = verticesArray.length / 3;
			var uvs = uvgen.generateSideWallUV(this, verticesArray, nextIndex - 6, nextIndex - 3, nextIndex - 2, nextIndex - 1);
			addUV(uvs[0]);
			addUV(uvs[1]);
			addUV(uvs[3]);
			addUV(uvs[1]);
			addUV(uvs[2]);
			addUV(uvs[3]);
		}
		function addVertex(index: Int) {
			verticesArray.push(placeholder[index * 3]);
			verticesArray.push(placeholder[index * 3 + 1]);
			verticesArray.push(placeholder[index * 3 + 2]);
		}
		function addUV(vector2: Vector2) {
			uvArray.push(vector2.x);
			uvArray.push(vector2.y);
		}
	}

	public function copy(source: ExtrudeGeometry): ExtrudeGeometry {
		super.copy(source);
		this.parameters = {
			shapes: source.parameters.shapes.copy(),
			options: {
				curveSegments: source.parameters.options.curveSegments,
				steps: source.parameters.options.steps,
				depth: source.parameters.options.depth,
				bevelEnabled: source.parameters.options.bevelEnabled,
				bevelThickness: source.parameters.options.bevelThickness,
				bevelSize: source.parameters.options.bevelSize,
				bevelOffset: source.parameters.options.bevelOffset,
				bevelSegments: source.parameters.options.bevelSegments,
				extrudePath: source.parameters.options.extrudePath != null ? source.parameters.options.extrudePath.clone() : null,
				UVGenerator: source.parameters.options.UVGenerator
			}
		};
		return this;
	}

	public function toJSON(): Dynamic {
		var data = super.toJSON();
		var shapes = this.parameters.shapes;
		var options = this.parameters.options;
		return toJSON(shapes, options, data);
	}

	public static function fromJSON(data: Dynamic, shapes: Array<Shape>): ExtrudeGeometry {
		var geometryShapes: Array<Shape> = [];
		for (j in 0...data.shapes.length) {
			var shape = shapes[data.shapes[j]];
			geometryShapes.push(shape);
		}
		var extrudePath = data.options.extrudePath;
		if (extrudePath != null) {
			data.options.extrudePath = Type.createInstance(Curves.getByName(extrudePath.type), [extrudePath]);
		}
		return new ExtrudeGeometry(geometryShapes, data.options);
	}

}

class WorldUVGenerator {

	public static function generateTopUV(geometry: ExtrudeGeometry, vertices: Array<Float>, indexA: Int, indexB: Int, indexC: Int): Array<Vector2> {
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

	public static function generateSideWallUV(geometry: ExtrudeGeometry, vertices: Array<Float>, indexA: Int, indexB: Int, indexC: Int, indexD: Int): Array<Vector2> {
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

function toJSON(shapes: Array<Shape>, options: {
	curveSegments: Int;
	steps: Int;
	depth: Float;
	bevelEnabled: Bool;
	bevelThickness: Float;
	bevelSize: Float;
	bevelOffset: Float;
	bevelSegments: Int;
	extrudePath: Curves.Curve;
	UVGenerator: WorldUVGenerator;
}, data: Dynamic): Dynamic {
	data.shapes = [];
	for (i in 0...shapes.length) {
		var shape = shapes[i];
		data.shapes.push(shape.uuid);
	}
	data.options = {
		curveSegments: options.curveSegments,
		steps: options.steps,
		depth: options.depth,
		bevelEnabled: options.bevelEnabled,
		bevelThickness: options.bevelThickness,
		bevelSize: options.bevelSize,
		bevelOffset: options.bevelOffset,
		bevelSegments: options.bevelSegments,
		extrudePath: options.extrudePath != null ? options.extrudePath.toJSON() : null,
		UVGenerator: options.UVGenerator
	};
	return data;
}