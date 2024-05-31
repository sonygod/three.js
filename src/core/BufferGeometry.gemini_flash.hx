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

	static var _id:Int = 0;

	public var id:Int;

	public var uuid:String;

	public var name:String;

	public var type:String;

	public var index:Null<BufferAttribute> = null;

	public var attributes:Map<String, BufferAttribute> = new Map();

	public var morphAttributes:Map<String, Array<BufferAttribute>> = new Map();

	public var morphTargetsRelative:Bool = false;

	public var groups:Array<{start:Int, count:Int, materialIndex:Int}> = [];

	public var boundingBox:Null<Box3> = null;

	public var boundingSphere:Null<Sphere> = null;

	public var drawRange:Dynamic = { start: 0, count: Math.POSITIVE_INFINITY };

	public var userData:Dynamic = {};

	public function new() {
		super();

		this.id = BufferGeometry._id++;

		this.uuid = MathUtils.generateUUID();

		this.name = "";
		this.type = "BufferGeometry";
	}

	public function getIndex():Null<BufferAttribute> {
		return this.index;
	}

	public function setIndex(index:Null<BufferAttribute>):BufferGeometry {
		this.index = index;
		return this;
	}

	public function setIndex(index:Array<Int>):BufferGeometry {
		this.index = if (Utils.arrayNeedsUint32(index)) new Uint32BufferAttribute(index, 1) else new Uint16BufferAttribute(index, 1);
		return this;
	}

	public function getAttribute(name:String):Null<BufferAttribute> {
		return this.attributes.get(name);
	}

	public function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry {
		this.attributes.set(name, attribute);
		return this;
	}

	public function deleteAttribute(name:String):BufferGeometry {
		this.attributes.remove(name);
		return this;
	}

	public function hasAttribute(name:String):Bool {
		return this.attributes.exists(name);
	}

	public function addGroup(start:Int, count:Int, materialIndex:Int = 0):Void {
		this.groups.push({ start: start, count: count, materialIndex: materialIndex });
	}

	public function clearGroups():Void {
		this.groups = [];
	}

	public function setDrawRange(start:Int, count:Int):Void {
		this.drawRange.start = start;
		this.drawRange.count = count;
	}

	public function applyMatrix4(matrix:Matrix4):BufferGeometry {
		var position = this.getAttribute("position");

		if (position != null) {
			position.applyMatrix4(matrix);
			position.needsUpdate = true;
		}

		var normal = this.getAttribute("normal");

		if (normal != null) {
			var normalMatrix = new Matrix3().getNormalMatrix(matrix);
			normal.applyNormalMatrix(normalMatrix);
			normal.needsUpdate = true;
		}

		var tangent = this.getAttribute("tangent");

		if (tangent != null) {
			tangent.transformDirection(matrix);
			tangent.needsUpdate = true;
		}

		if (this.boundingBox != null) {
			this.computeBoundingBox();
		}

		if (this.boundingSphere != null) {
			this.computeBoundingSphere();
		}

		return this;
	}

	public function applyQuaternion(q:Quaternion):BufferGeometry {
		var _m1 = new Matrix4().makeRotationFromQuaternion(q);
		this.applyMatrix4(_m1);
		return this;
	}

	public function rotateX(angle:Float):BufferGeometry {
		var _m1 = new Matrix4().makeRotationX(angle);
		this.applyMatrix4(_m1);
		return this;
	}

	public function rotateY(angle:Float):BufferGeometry {
		var _m1 = new Matrix4().makeRotationY(angle);
		this.applyMatrix4(_m1);
		return this;
	}

	public function rotateZ(angle:Float):BufferGeometry {
		var _m1 = new Matrix4().makeRotationZ(angle);
		this.applyMatrix4(_m1);
		return this;
	}

	public function translate(x:Float, y:Float, z:Float):BufferGeometry {
		var _m1 = new Matrix4().makeTranslation(x, y, z);
		this.applyMatrix4(_m1);
		return this;
	}

	public function scale(x:Float, y:Float, z:Float):BufferGeometry {
		var _m1 = new Matrix4().makeScale(x, y, z);
		this.applyMatrix4(_m1);
		return this;
	}

	public function lookAt(vector:Vector3):BufferGeometry {
		var _obj = new Object3D();
		_obj.lookAt(vector);
		_obj.updateMatrix();
		this.applyMatrix4(_obj.matrix);
		return this;
	}

	public function center():BufferGeometry {
		this.computeBoundingBox();
		var _offset = new Vector3();
		this.boundingBox.getCenter(_offset);
		_offset.negate();
		this.translate(_offset.x, _offset.y, _offset.z);
		return this;
	}

	public function setFromPoints(points:Array<Vector3>):BufferGeometry {
		var position = [];

		for (i in 0...points.length) {
			var point = points[i];
			position.push(point.x, point.y, point.z);
		}

		this.setAttribute("position", new Float32BufferAttribute(position, 3));
		return this;
	}

	public function computeBoundingBox():Void {
		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}

		var position = this.getAttribute("position");
		var morphAttributesPosition = this.morphAttributes.get("position");

		if (position != null && position.isGLBufferAttribute) {
			console.error("THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.", this);
			this.boundingBox.set(new Vector3(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY), new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY));
			return;
		}

		if (position != null) {
			this.boundingBox.setFromBufferAttribute(position);

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var _box = new Box3().setFromBufferAttribute(morphAttribute);

					if (this.morphTargetsRelative) {
						var _vector = new Vector3().addVectors(this.boundingBox.min, _box.min);
						this.boundingBox.expandByPoint(_vector);
						_vector.addVectors(this.boundingBox.max, _box.max);
						this.boundingBox.expandByPoint(_vector);
					} else {
						this.boundingBox.expandByPoint(_box.min);
						this.boundingBox.expandByPoint(_box.max);
					}
				}
			}
		} else {
			this.boundingBox.makeEmpty();
		}

		if (Math.isNaN(this.boundingBox.min.x) || Math.isNaN(this.boundingBox.min.y) || Math.isNaN(this.boundingBox.min.z)) {
			console.error("THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The \"position\" attribute is likely to have NaN values.", this);
		}
	}

	public function computeBoundingSphere():Void {
		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}

		var position = this.getAttribute("position");
		var morphAttributesPosition = this.morphAttributes.get("position");

		if (position != null && position.isGLBufferAttribute) {
			console.error("THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.", this);
			this.boundingSphere.set(new Vector3(), Math.POSITIVE_INFINITY);
			return;
		}

		if (position != null) {
			var center = this.boundingSphere.center;
			var _box = new Box3().setFromBufferAttribute(position);

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var _boxMorphTargets = new Box3().setFromBufferAttribute(morphAttribute);

					if (this.morphTargetsRelative) {
						var _vector = new Vector3().addVectors(_box.min, _boxMorphTargets.min);
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
				var _vector = new Vector3().fromBufferAttribute(position, i);
				maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
			}

			if (morphAttributesPosition != null) {
				for (i in 0...morphAttributesPosition.length) {
					var morphAttribute = morphAttributesPosition[i];
					var morphTargetsRelative = this.morphTargetsRelative;

					for (j in 0...morphAttribute.count) {
						var _vector = new Vector3().fromBufferAttribute(morphAttribute, j);

						if (morphTargetsRelative) {
							var _offset = new Vector3().fromBufferAttribute(position, j);
							_vector.add(_offset);
						}

						maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(_vector));
					}
				}
			}

			this.boundingSphere.radius = Math.sqrt(maxRadiusSq);

			if (Math.isNaN(this.boundingSphere.radius)) {
				console.error("THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The \"position\" attribute is likely to have NaN values.", this);
			}
		}
	}

	public function computeTangents():Void {
		var index = this.index;
		var attributes = this.attributes;

		if (index == null || attributes.get("position") == null || attributes.get("normal") == null || attributes.get("uv") == null) {
			console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");
			return;
		}

		var positionAttribute = attributes.get("position");
		var normalAttribute = attributes.get("normal");
		var uvAttribute = attributes.get("uv");

		if (!this.hasAttribute("tangent")) {
			this.setAttribute("tangent", new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
		}

		var tangentAttribute = this.getAttribute("tangent");
		var tan1 = [];
		var tan2 = [];

		for (i in 0...positionAttribute.count) {
			tan1[i] = new Vector3();
			tan2[i] = new Vector3();
		}

		var vA = new Vector3();
		var vB = new Vector3();
		var vC = new Vector3();
		var uvA = new Vector2();
		var uvB = new Vector2();
		var uvC = new Vector2();
		var sdir = new Vector3();
		var tdir = new Vector3();

		function handleTriangle(a:Int, b:Int, c:Int):Void {
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
			var r = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

			if (!Math.isFinite(r)) {
				return;
			}

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
			groups = [{ start: 0, count: index.count }];
		}

		for (i in 0...groups.length) {
			var group = groups[i];
			var start = group.start;
			var count = group.count;

			for (j in start...start + count) {
				handleTriangle(index.getX(j + 0), index.getX(j + 1), index.getX(j + 2));
			}
		}

		var tmp = new Vector3();
		var tmp2 = new Vector3();
		var n = new Vector3();
		var n2 = new Vector3();

		function handleVertex(v:Int):Void {
			n.fromBufferAttribute(normalAttribute, v);
			n2.copy(n);
			var t = tan1[v];
			tmp.copy(t);
			tmp.sub(n.multiplyScalar(n.dot(t))).normalize();
			tmp2.crossVectors(n2, t);
			var test = tmp2.dot(tan2[v]);
			var w = if (test < 0.0) -1.0 else 1.0;
			tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
		}

		for (i in 0...groups.length) {
			var group = groups[i];
			var start = group.start;
			var count = group.count;

			for (j in start...start + count) {
				handleVertex(index.getX(j + 0));
				handleVertex(index.getX(j + 1));
				handleVertex(index.getX(j + 2));
			}
		}
	}

	public function computeVertexNormals():Void {
		var index = this.index;
		var positionAttribute = this.getAttribute("position");

		if (positionAttribute != null) {
			var normalAttribute = this.getAttribute("normal");

			if (normalAttribute == null) {
				normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
				this.setAttribute("normal", normalAttribute);
			} else {
				for (i in 0...normalAttribute.count) {
					normalAttribute.setXYZ(i, 0, 0, 0);
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
			} else {
				for (i in 0...positionAttribute.count) {
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

			this.normalizeNormals();
			normalAttribute.needsUpdate = true;
		}
	}

	public function normalizeNormals():Void {
		var normals = this.getAttribute("normal");

		for (i in 0...normals.count) {
			var _vector = new Vector3().fromBufferAttribute(normals, i);
			_vector.normalize();
			normals.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}
	}

	public function toNonIndexed():BufferGeometry {
		function convertBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
			var array = attribute.array;
			var itemSize = attribute.itemSize;
			var normalized = attribute.normalized;
			var array2 = new array.constructor(indices.length * itemSize);
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

		if (this.index == null) {
			console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.");
			return this;
		}

		var geometry2 = new BufferGeometry();
		var indices = this.index.array;
		var attributes = this.attributes;

		for (name in attributes.keys()) {
			var attribute = attributes.get(name);
			var newAttribute = convertBufferAttribute(attribute, indices);
			geometry2.setAttribute(name, newAttribute);
		}

		var morphAttributes = this.morphAttributes;

		for (name in morphAttributes.keys()) {
			var morphArray = [];
			var morphAttribute = morphAttributes.get(name);

			for (i in 0...morphAttribute.length) {
				var attribute = morphAttribute[i];
				var newAttribute = convertBufferAttribute(attribute, indices);
				morphArray.push(newAttribute);
			}

			geometry2.morphAttributes.set(name, morphArray);
		}

		geometry2.morphTargetsRelative = this.morphTargetsRelative;

		var groups = this.groups;

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
		data.uuid = this.uuid;
		data.type = this.type;

		if (this.name != "") {
			data.name = this.name;
		}

		if (this.userData.keys().length > 0) {
			data.userData = this.userData;
		}

		if (this.parameters != null) {
			var parameters = this.parameters;

			for (key in parameters.keys()) {
				if (parameters.get(key) != null) {
					data[key] = parameters.get(key);
				}
			}

			return data;
		}

		data.data = { attributes: {} };

		var index = this.index;

		if (index != null) {
			data.data.index = {
				type: index.array.constructor.name,
				array: index.array.copy()
			};
		}

		var attributes = this.attributes;

		for (key in attributes.keys()) {
			var attribute = attributes.get(key);
			data.data.attributes[key] = attribute.toJSON(data.data);
		}

		var morphAttributes = new Map<String, Array<Dynamic>>();
		var hasMorphAttributes = false;

		for (key in this.morphAttributes.keys()) {
			var attributeArray = this.morphAttributes.get(key);
			var array = [];

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
			data.data.morphTargetsRelative = this.morphTargetsRelative;
		}

		var groups = this.groups;

		if (groups.length > 0) {
			data.data.groups = groups.copy();
		}

		var boundingSphere = this.boundingSphere;

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
		this.index = null;
		this.attributes = new Map();
		this.morphAttributes = new Map();
		this.groups = [];
		this.boundingBox = null;
		this.boundingSphere = null;

		var data = {};
		this.name = source.name;
		var index = source.index;

		if (index != null) {
			this.setIndex(index.clone(data));
		}

		var attributes = source.attributes;

		for (name in attributes.keys()) {
			var attribute = attributes.get(name);
			this.setAttribute(name, attribute.clone(data));
		}

		var morphAttributes = source.morphAttributes;

		for (name in morphAttributes.keys()) {
			var array = [];
			var morphAttribute = morphAttributes.get(name);

			for (i in 0...morphAttribute.length) {
				array.push(morphAttribute[i].clone(data));
			}

			this.morphAttributes.set(name, array);
		}

		this.morphTargetsRelative = source.morphTargetsRelative;

		var groups = source.groups;

		for (i in 0...groups.length) {
			var group = groups[i];
			this.addGroup(group.start, group.count, group.materialIndex);
		}

		var boundingBox = source.boundingBox;

		if (boundingBox != null) {
			this.boundingBox = boundingBox.clone();
		}

		var boundingSphere = source.boundingSphere;

		if (boundingSphere != null) {
			this.boundingSphere = boundingSphere.clone();
		}

		this.drawRange.start = source.drawRange.start;
		this.drawRange.count = source.drawRange.count;
		this.userData = source.userData;

		return this;
	}

	public function dispose():Void {
		this.dispatchEvent({ type: "dispose" });
	}
}