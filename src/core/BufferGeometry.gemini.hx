import three.math.Vector3;
import three.math.Vector2;
import three.math.Box3;
import three.core.EventDispatcher;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.core.Uint16BufferAttribute;
import three.core.Uint32BufferAttribute;
import three.math.Sphere;
import three.core.Object3D;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.MathUtils;
import three.utils.Utils;

class BufferGeometry extends EventDispatcher {
	public var isBufferGeometry:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var name:String = "";
	public var type:String = "BufferGeometry";
	public var index:Null<BufferAttribute> = null;
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var morphAttributes:Map<String, Array<BufferAttribute>> = new Map();
	public var morphTargetsRelative:Bool = false;
	public var groups:Array<{ start:Int, count:Int, materialIndex:Int }> = [];
	public var boundingBox:Null<Box3> = null;
	public var boundingSphere:Null<Sphere> = null;
	public var drawRange:{ start:Int, count:Int } = { start: 0, count: Int.POSITIVE_INFINITY };
	public var userData:Dynamic = {};

	public static var _id:Int = 0;

	static function init() {
		_id = 0;
	}

	public function new() {
		super();
		id = _id++;
		uuid = MathUtils.generateUUID();
	}

	public function getIndex():Null<BufferAttribute> {
		return index;
	}

	public function setIndex(index:Null<BufferAttribute>):BufferGeometry {
		this.index = index;
		return this;
	}

	public function setIndex(index:Array<Int>):BufferGeometry {
		if (Utils.arrayNeedsUint32(index)) {
			this.index = new Uint32BufferAttribute(index, 1);
		} else {
			this.index = new Uint16BufferAttribute(index, 1);
		}
		return this;
	}

	public function getAttribute(name:String):Null<BufferAttribute> {
		return attributes.get(name);
	}

	public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
		attributes.set(name, attribute);
		return this;
	}

	public function deleteAttribute(name:String):BufferGeometry {
		attributes.remove(name);
		return this;
	}

	public function hasAttribute(name:String):Bool {
		return attributes.exists(name);
	}

	public function addGroup(start:Int, count:Int, materialIndex:Int = 0):Void {
		groups.push({ start: start, count: count, materialIndex: materialIndex });
	}

	public function clearGroups():Void {
		groups = [];
	}

	public function setDrawRange(start:Int, count:Int):Void {
		drawRange.start = start;
		drawRange.count = count;
	}

	public function applyMatrix4(matrix:Matrix4):BufferGeometry {
		var position = attributes.get("position");
		if (position != null) {
			position.applyMatrix4(matrix);
			position.needsUpdate = true;
		}

		var normal = attributes.get("normal");
		if (normal != null) {
			var normalMatrix = new Matrix3().getNormalMatrix(matrix);
			normal.applyNormalMatrix(normalMatrix);
			normal.needsUpdate = true;
		}

		var tangent = attributes.get("tangent");
		if (tangent != null) {
			tangent.transformDirection(matrix);
			tangent.needsUpdate = true;
		}

		if (boundingBox != null) {
			computeBoundingBox();
		}

		if (boundingSphere != null) {
			computeBoundingSphere();
		}

		return this;
	}

	public function applyQuaternion(q:Quaternion):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeRotationFromQuaternion(q);
		applyMatrix4(_m1);
		return this;
	}

	public function rotateX(angle:Float):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeRotationX(angle);
		applyMatrix4(_m1);
		return this;
	}

	public function rotateY(angle:Float):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeRotationY(angle);
		applyMatrix4(_m1);
		return this;
	}

	public function rotateZ(angle:Float):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeRotationZ(angle);
		applyMatrix4(_m1);
		return this;
	}

	public function translate(x:Float, y:Float, z:Float):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeTranslation(x, y, z);
		applyMatrix4(_m1);
		return this;
	}

	public function scale(x:Float, y:Float, z:Float):BufferGeometry {
		var _m1 = new Matrix4();
		_m1.makeScale(x, y, z);
		applyMatrix4(_m1);
		return this;
	}

	public function lookAt(vector:Vector3):BufferGeometry {
		var _obj = new Object3D();
		_obj.lookAt(vector);
		_obj.updateMatrix();
		applyMatrix4(_obj.matrix);
		return this;
	}

	public function center():BufferGeometry {
		computeBoundingBox();
		boundingBox.getCenter(new Vector3()).negate();
		translate(boundingBox.min.x, boundingBox.min.y, boundingBox.min.z);
		return this;
	}

	public function setFromPoints(points:Array<Vector3>):BufferGeometry {
		var position = new Array<Float>();
		for (i in 0...points.length) {
			var point = points[i];
			position.push(point.x, point.y, point.z);
		}
		setAttribute("position", new Float32BufferAttribute(position, 3));
		return this;
	}

	public function computeBoundingBox():Void {
		if (boundingBox == null) {
			boundingBox = new Box3();
		}
		var position = attributes.get("position");
		var morphAttributesPosition = morphAttributes.get("position");

		if (position != null && position.isGLBufferAttribute) {
			throw "THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.";
		}

		if (position != null) {
			boundingBox.setFromBufferAttribute(position);

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var _box = new Box3();
					_box.setFromBufferAttribute(morphAttribute);

					if (morphTargetsRelative) {
						var _vector = new Vector3();
						_vector.addVectors(boundingBox.min, _box.min);
						boundingBox.expandByPoint(_vector);

						_vector.addVectors(boundingBox.max, _box.max);
						boundingBox.expandByPoint(_vector);
					} else {
						boundingBox.expandByPoint(_box.min);
						boundingBox.expandByPoint(_box.max);
					}
				}
			}
		} else {
			boundingBox.makeEmpty();
		}

		if (Math.isNaN(boundingBox.min.x) || Math.isNaN(boundingBox.min.y) || Math.isNaN(boundingBox.min.z)) {
			throw "THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The \"position\" attribute is likely to have NaN values.";
		}
	}

	public function computeBoundingSphere():Void {
		if (boundingSphere == null) {
			boundingSphere = new Sphere();
		}
		var position = attributes.get("position");
		var morphAttributesPosition = morphAttributes.get("position");

		if (position != null && position.isGLBufferAttribute) {
			throw "THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.";
		}

		if (position != null) {
			var center = boundingSphere.center;

			var _box = new Box3();
			_box.setFromBufferAttribute(position);

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var _boxMorphTargets = new Box3();
					_boxMorphTargets.setFromBufferAttribute(morphAttribute);

					if (morphTargetsRelative) {
						var _vector = new Vector3();
						_vector.addVectors(_box.min, _boxMorphTargets.min);
						_box.expandByPoint(_vector);

						_vector.addVectors(_box.max, _boxMorphTargets.max);
						_box.expandByPoint(_vector);
					} else {
						_box.expandByPoint(_boxMorphTargets.min);
						_box.expandByPoint(_boxMorphTargets.max);
					}
				}
			}

			_box.getCenter(center);

			var maxRadiusSq = 0.;

			for (i in 0...position.count) {
				var _vector = new Vector3();
				_vector.fromBufferAttribute(position, i);
				maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
			}

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var morphTargetsRelative = this.morphTargetsRelative;

					for (j in 0...morphAttribute.count) {
						var _vector = new Vector3();
						_vector.fromBufferAttribute(morphAttribute, j);

						if (morphTargetsRelative) {
							var _offset = new Vector3();
							_offset.fromBufferAttribute(position, j);
							_vector.add(_offset);
						}

						maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
					}
				}
			}

			boundingSphere.radius = Math.sqrt(maxRadiusSq);

			if (Math.isNaN(boundingSphere.radius)) {
				throw "THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The \"position\" attribute is likely to have NaN values.";
			}
		}
	}

	public function computeTangents():Void {
		var index = this.index;
		var attributes = this.attributes;

		if (index == null || attributes.get("position") == null || attributes.get("normal") == null || attributes.get("uv") == null) {
			throw "THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)";
		}

		var positionAttribute = attributes.get("position");
		var normalAttribute = attributes.get("normal");
		var uvAttribute = attributes.get("uv");

		if (!hasAttribute("tangent")) {
			setAttribute("tangent", new BufferAttribute(new Float32Array(positionAttribute.count * 4), 4));
		}

		var tangentAttribute = attributes.get("tangent");

		var tan1:Array<Vector3> = [];
		var tan2:Array<Vector3> = [];
		for (i in 0...positionAttribute.count) {
			tan1.push(new Vector3());
			tan2.push(new Vector3());
		}

		var vA = new Vector3();
		var vB = new Vector3();
		var vC = new Vector3();
		var uvA = new Vector2();
		var uvB = new Vector2();
		var uvC = new Vector2();
		var sdir = new Vector3();
		var tdir = new Vector3();

		function handleTriangle(a:Int, b:Int, c:Int) {
			vA.fromBufferAttribute(positionAttribute, a);
			vB.fromBufferAttribute(positionAttribute, b);
			vC.fromBufferAttribute(positionAttribute, c);

			uvA.fromBufferAttribute(uvAttribute, a);
			uvB.fromBufferAttribute(uvAttribute, b);
			uvC.fromBufferAttribute(uvAttribute, c);

			vB.sub(vA);
			vC.sub(vA);

			uvB.sub(uvA);
			uvC.sub(uvA);

			var r = 1. / (uvB.x * uvC.y - uvC.x * uvB.y);

			if (!Math.isFinite(r)) return;

			sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
			tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);

			tan1[a].add(sdir);
			tan1[b].add(sdir);
			tan1[c].add(sdir);

			tan2[a].add(tdir);
			tan2[b].add(tdir);
			tan2[c].add(tdir);
		}

		var groups = this.groups;
		if (groups.length == 0) {
			groups = [{
				start: 0,
				count: index.count
			}];
		}

		for (i in 0...groups.length) {
			var group = groups[i];
			var start = group.start;
			var count = group.count;
			for (j in start...(start + count)) {
				if (j % 3 == 0) {
					handleTriangle(
						index.getX(j + 0),
						index.getX(j + 1),
						index.getX(j + 2)
					);
				}
			}
		}

		var tmp = new Vector3();
		var tmp2 = new Vector3();
		var n = new Vector3();
		var n2 = new Vector3();

		function handleVertex(v:Int) {
			n.fromBufferAttribute(normalAttribute, v);
			n2.copy(n);

			var t = tan1[v];

			tmp.copy(t);
			tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

			tmp2.crossVectors(n2, t);
			var test = tmp2.dot(tan2[v]);
			var w = (test < 0.) ? -1. : 1.;

			tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
		}

		for (i in 0...groups.length) {
			var group = groups[i];
			var start = group.start;
			var count = group.count;
			for (j in start...(start + count)) {
				if (j % 3 == 0) {
					handleVertex(index.getX(j + 0));
					handleVertex(index.getX(j + 1));
					handleVertex(index.getX(j + 2));
				}
			}
		}
	}

	public function computeVertexNormals():Void {
		var index = this.index;
		var positionAttribute = attributes.get("position");

		if (positionAttribute != null) {
			var normalAttribute = attributes.get("normal");

			if (normalAttribute == null) {
				normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
				setAttribute("normal", normalAttribute);
			} else {
				for (i in 0...normalAttribute.count) {
					normalAttribute.setXYZ(i, 0., 0., 0.);
				}
			}

			var pA = new Vector3();
			var pB = new Vector3();
			var pC = new Vector3();
			var nA = new Vector3();
			var nB = new Vector3();
			var nC = new Vector3();
			var cb = new Vector3();
			var ab = new Vector3();

			if (index != null) {
				for (i in 0...index.count) {
					if (i % 3 == 0) {
						var vA = index.getX(i + 0);
						var vB = index.getX(i + 1);
						var vC = index.getX(i + 2);

						pA.fromBufferAttribute(positionAttribute, vA);
						pB.fromBufferAttribute(positionAttribute, vB);
						pC.fromBufferAttribute(positionAttribute, vC);

						cb.subVectors(pC, pB);
						ab.subVectors(pA, pB);
						cb.cross(ab);

						nA.fromBufferAttribute(normalAttribute, vA);
						nB.fromBufferAttribute(normalAttribute, vB);
						nC.fromBufferAttribute(normalAttribute, vC);

						nA.add(cb);
						nB.add(cb);
						nC.add(cb);

						normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
						normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
						normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
					}
				}
			} else {
				for (i in 0...positionAttribute.count) {
					if (i % 3 == 0) {
						pA.fromBufferAttribute(positionAttribute, i + 0);
						pB.fromBufferAttribute(positionAttribute, i + 1);
						pC.fromBufferAttribute(positionAttribute, i + 2);

						cb.subVectors(pC, pB);
						ab.subVectors(pA, pB);
						cb.cross(ab);

						normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
						normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
						normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
					}
				}
			}
			normalizeNormals();
			normalAttribute.needsUpdate = true;
		}
	}

	public function normalizeNormals():Void {
		var normals = attributes.get("normal");

		if (normals == null) return;

		for (i in 0...normals.count) {
			var _vector = new Vector3();
			_vector.fromBufferAttribute(normals, i);
			_vector.normalize();
			normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
	}

	public function toNonIndexed():BufferGeometry {
		function convertBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
			var array = attribute.array;
			var itemSize = attribute.itemSize;
			var normalized = attribute.normalized;

			var array2 = new attribute.array.constructor(indices.length * itemSize);

			var index = 0;
			var index2 = 0;

			for (i in 0...indices.length) {
				if (attribute.isInterleavedBufferAttribute) {
					index = indices[i] * attribute.data.stride + attribute.offset;
				} else {
					index = indices[i] * itemSize;
				}

				for (j in 0...itemSize) {
					array2[index2++] = array[index++];
				}
			}

			return new BufferAttribute(array2, itemSize, normalized);
		}

		if (index == null) {
			throw "THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.";
		}

		var geometry2 = new BufferGeometry();

		var indices = index.array;
		var attributes = this.attributes;

		for (name in attributes.keys()) {
			var attribute = attributes.get(name);
			var newAttribute = convertBufferAttribute(attribute, indices);
			geometry2.setAttribute(name, newAttribute);
		}

		for (name in morphAttributes.keys()) {
			var morphArray:Array<BufferAttribute> = [];
			var morphAttribute = morphAttributes.get(name);

			for (i in 0...morphAttribute.length) {
				var attribute = morphAttribute[i];
				var newAttribute = convertBufferAttribute(attribute, indices);
				morphArray.push(newAttribute);
			}

			geometry2.morphAttributes.set(name, morphArray);
		}

		geometry2.morphTargetsRelative = morphTargetsRelative;

		for (i in 0...groups.length) {
			var group = groups[i];
			geometry2.addGroup(group.start, group.count, group.materialIndex);
		}

		return geometry2;
	}

	public function toJSON():Dynamic {
		var data = {
			metadata: {
				version: 4.6,
				type: "BufferGeometry",
				generator: "BufferGeometry.toJSON"
			}
		};

		data.uuid = uuid;
		data.type = type;
		if (name != "") data.name = name;
		if (userData != null) data.userData = userData;

		if (parameters != null) {
			for (key in parameters.keys()) {
				if (parameters.get(key) != null) data[key] = parameters.get(key);
			}
			return data;
		}

		data.data = { attributes: {} };

		if (index != null) {
			data.data.index = {
				type: index.array.constructor.name,
				array: index.array
			};
		}

		for (key in attributes.keys()) {
			var attribute = attributes.get(key);
			data.data.attributes[key] = attribute.toJSON(data.data);
		}

		var morphAttributes:Map<String, Array<Dynamic>> = new Map();
		var hasMorphAttributes:Bool = false;

		for (key in this.morphAttributes.keys()) {
			var attributeArray = this.morphAttributes.get(key);
			var array:Array<Dynamic> = [];

			for (i in 0...attributeArray.length) {
				var attribute = attributeArray[i];
				array.push(attribute.toJSON(data.data));
			}

			if (array.length > 0) {
				morphAttributes.set(key, array);
				hasMorphAttributes = true;
			}
		}

		if (hasMorphAttributes) {
			data.data.morphAttributes = morphAttributes;
			data.data.morphTargetsRelative = morphTargetsRelative;
		}

		if (groups.length > 0) {
			data.data.groups = groups;
		}

		if (boundingSphere != null) {
			data.data.boundingSphere = {
				center: boundingSphere.center.toArray(),
				radius: boundingSphere.radius
			};
		}

		return data;
	}

	public function clone():BufferGeometry {
		return new BufferGeometry().copy(this);
	}

	public function copy(source:BufferGeometry):BufferGeometry {
		index = null;
		attributes = new Map();
		morphAttributes = new Map();
		groups = [];
		boundingBox = null;
		boundingSphere = null;

		name = source.name;

		if (source.index != null) {
			index = source.index.clone();
		}

		for (name in source.attributes.keys()) {
			var attribute = source.attributes.get(name);
			attributes.set(name, attribute.clone());
		}

		for (name in source.morphAttributes.keys()) {
			var array:Array<BufferAttribute> = [];
			var morphAttribute = source.morphAttributes.get(name);

			for (i in 0...morphAttribute.length) {
				array.push(morphAttribute[i].clone());
			}

			morphAttributes.set(name, array);
		}

		morphTargetsRelative = source.morphTargetsRelative;

		for (i in 0...source.groups.length) {
			var group = source.groups[i];
			addGroup(group.start, group.count, group.materialIndex);
		}

		if (source.boundingBox != null) {
			boundingBox = source.boundingBox.clone();
		}

		if (source.boundingSphere != null) {
			boundingSphere = source.boundingSphere.clone();
		}

		drawRange.start = source.drawRange.start;
		drawRange.count = source.drawRange.count;

		userData = source.userData;

		return this;
	}

	public function dispose():Void {
		dispatchEvent({ type: "dispose" });
	}
}