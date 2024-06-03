import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int, count:Int };
	public var updateRanges:Array<{ start:Int, count:Int }>;
	public var gpuType:Int;
	public var version:Int;
	public var onUploadCallback:Void->Void = null;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.isOfType(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.usage = StaticDrawUsage;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.gpuType = FloatType;

		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
		}
	}

	public function get updateRange():{ offset:Int, count:Int } {
		WarnOnce.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;

		this.usage = source.usage;
		this.gpuType = source.gpuType;

		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;

		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		var _vector2 = new Vector2();
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			var _vector = new Vector3();
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}

		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) {
			value = MathUtils.denormalize(value, this.array);
		}
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) {
			value = MathUtils.normalize(value, this.array);
		}
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};

		if (this.name != "") {
			data.name = this.name;
		}
		if (this.usage != StaticDrawUsage) {
			data.usage = this.usage;
		}

		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var index:BufferAttribute;

	public function new() {
	}
}

class Geometry {
	public var vertices:Array<Vector3> = [];
	public var faces:Array<Dynamic> = [];

	public function new() {
	}
}

class Mesh {
	public var geometry:Geometry;
	public var material:Dynamic;

	public function new(geometry:Geometry, material:Dynamic) {
		this.geometry = geometry;
		this.material = material;
	}
}

class Scene {
	public var children:Array<Mesh> = [];
	public var background:Dynamic;

	public function new() {
	}

	public function addChild(mesh:Mesh) {
		children.push(mesh);
	}
}

class Renderer {
	public function new() {
	}

	public function render(scene:Scene, camera:Dynamic) {
	}
}

class Camera {
	public function new() {
	}
}

class WebGLRenderer extends Renderer {
	public function new() {
		super();
	}
}

class PerspectiveCamera extends Camera {
	public function new() {
		super();
	}
}

class BasicMaterial {
	public var color:Int;

	public function new(color:Int) {
		this.color = color;
	}
}

class ShaderMaterial {
	public var vertexShader:String;
	public var fragmentShader:String;
	public var uniforms:Map<String, Dynamic>;

	public function new(vertexShader:String, fragmentShader:String, uniforms:Map<String, Dynamic>) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.uniforms = uniforms;
	}
}

class Clock {
	public var time:Float;
	public var delta:Float;

	public function new() {
	}

	public function getDelta():Float {
		return delta;
	}

	public function getElapsedTime():Float {
		return time;
	}
}

class AnimationMixer {
	public function new() {
	}

	public function clipAction(clip:Dynamic):Dynamic {
		return null;
	}
}

class AnimationClip {
	public function new() {
	}
}

class AnimationAction {
	public var time:Float;

	public function new() {
	}

	public function play():Dynamic {
		return null;
	}

	public function stop():Dynamic {
		return null;
	}

	public function setTime(time:Float):Void {
		this.time = time;
	}

	public function setWeight(weight:Float):Void {
	}
}

class Object3D {
	public var position:Vector3;
	public var rotation:Vector3;
	public var scale:Vector3;
	public var children:Array<Object3D> = [];
	public var parent:Object3D;
	public var up:Vector3;

	public function new() {
		position = new Vector3();
		rotation = new Vector3();
		scale = new Vector3(1, 1, 1);
		up = new Vector3(0, 1, 0);
	}

	public function add(child:Object3D):Void {
		children.push(child);
		child.parent = this;
	}

	public function remove(child:Object3D):Void {
		var index = children.indexOf(child);
		if (index != -1) {
			children.splice(index, 1);
			child.parent = null;
		}
	}
}

class Group extends Object3D {
	public function new() {
		super();
	}
}

class SkinnedMesh extends Mesh {
	public var skeleton:Skeleton;

	public function new(geometry:Geometry, material:Dynamic, skeleton:Skeleton) {
		super(geometry, material);
		this.skeleton = skeleton;
	}
}

class Skeleton {
	public var bones:Array<Bone>;

	public function new(bones:Array<Bone>) {
		this.bones = bones;
	}
}

class Bone extends Object3D {
	public function new() {
		super();
	}
}

class BoxGeometry extends Geometry {
	public function new(width:Float, height:Float, depth:Float) {
		super();
		// ... BoxGeometry logic ...
	}
}

class SphereGeometry extends Geometry {
	public function new(radius:Float, widthSegments:Int, heightSegments:Int) {
		super();
		// ... SphereGeometry logic ...
	}
}

class PlaneGeometry extends Geometry {
	public function new(width:Float, height:Float) {
		super();
		// ... PlaneGeometry logic ...
	}
}

class CylinderGeometry extends Geometry {
	public function new(radiusTop:Float, radiusBottom:Float, height:Float, radialSegments:Int, heightSegments:Int, openEnded:Bool, thetaStart:Float, thetaLength:Float) {
		super();
		// ... CylinderGeometry logic ...
	}
}

class TorusGeometry extends Geometry {
	public function new(radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float) {
		super();
		// ... TorusGeometry logic ...
	}
}

class TorusKnotGeometry extends Geometry {
	public function new(radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int) {
		super();
		// ... TorusKnotGeometry logic ...
	}
}

class TextGeometry extends Geometry {
	public function new(text:String, parameters:Dynamic) {
		super();
		// ... TextGeometry logic ...
	}
}

class LineBasicMaterial extends BasicMaterial {
	public function new(color:Int) {
		super(color);
	}
}

class LineSegments extends Mesh {
	public function new(geometry:Geometry, material:LineBasicMaterial) {
		super(geometry, material);
	}
}

class Points extends Mesh {
	public function new(geometry:Geometry, material:Dynamic) {
		super(geometry, material);
	}
}

class PointsMaterial extends BasicMaterial {
	public var size:Float;

	public function new(color:Int, size:Float) {
		super(color);
		this.size = size;
	}
}

class Raycaster {
	public function new() {
	}

	public function intersectObject(object:Object3D, recursive:Bool = false):Array<Dynamic> {
		return [];
	}
}

class Vector4 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setHex(hex:Int):Void {
		this.r = ((hex >> 16) & 255) / 255;
		this.g = ((hex >> 8) & 255) / 255;
		this.b = (hex & 255) / 255;
	}

	public function getHex():Int {
		return ((r * 255) << 16) | ((g * 255) << 8) | (b * 255);
	}

	public function getStyle():String {
		return "rgb(" + Math.floor(r * 255) + "," + Math.floor(g * 255) + "," + Math.floor(b * 255) + ")";
	}
}

class Euler {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Quaternion {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Matrix3 {
	public function new() {
	}
}

class Matrix4 {
	public function new() {
	}
}

class AxesHelper extends Object3D {
	public function new(size:Float = 1) {
		super();
		// ... AxesHelper logic ...
	}
}

class GridHelper extends Object3D {
	public function new(size:Float, divisions:Int, color1:Color, color2:Color) {
		super();
		// ... GridHelper logic ...
	}
}

class DirectionalLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class AmbientLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class SpotLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
	}
}

class PointLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
	}
}

class HemisphereLight extends Object3D {
	public var color:Color;
	public var groundColor:Color;
	public var intensity:Float;

	public function new(color:Color, groundColor:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.groundColor = groundColor;
		this.intensity = intensity;
	}
}

class RectAreaLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var width:Float;
	public var height:Float;

	public function new(color:Color, intensity:Float, width:Float, height:Float) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.width = width;
		this.height = height;
	}
}

class LightHelper extends Object3D {
	public function new(light:Object3D, size:Float = 1) {
		super();
		// ... LightHelper logic ...
	}
}

class CameraHelper extends Object3D {
	public function new(camera:Camera, size:Float = 1) {
		super();
		// ... CameraHelper logic ...
	}
}

class SkeletonHelper extends Object3D {
	public function new(object:SkinnedMesh) {
		super();
		// ... SkeletonHelper logic ...
	}
}

class BoxHelper extends Object3D {
	public function new(object:Object3D, color:Color = null) {
		super();
		// ... BoxHelper logic ...
	}
}

class PlaneHelper extends Object3D {
	public function new(plane:Dynamic, size:Float, color:Color = null) {
		super();
		// ... PlaneHelper logic ...
	}
}

class ArrowHelper extends Object3D {
	public function new(dir:Vector3, origin:Vector3 = null, length:Float = 1, color:Color = null, headLength:Float = 0.2, headWidth:Float = 0.2) {
		super();
		// ... ArrowHelper logic ...
	}
}

class Sprite extends Object3D {
	public var material:Dynamic;

	public function new(material:Dynamic) {
		super();
		this.material = material;
	}
}

class SpriteMaterial extends BasicMaterial {
	public var map:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;

	public function new(parameters:Dynamic = null) {
		super(0xffffff);
		// ... SpriteMaterial logic ...
	}
}

class Texture {
	public function new(image:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
	}

	public function set needsUpdate(value:Bool) {
	}
}

class CanvasTexture extends Texture {
	public function new(canvas:Dynamic) {
		super(canvas);
	}
}

class DataTexture extends Texture {
	public var image:Dynamic;
	public var mapping:Dynamic;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;

	public function new(data:Dynamic, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, anisotropy:Int = null) {
		this.image = data;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
	}
}

class CubeTexture extends Texture {
	public function new(images:Array<Dynamic>, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class VideoTexture extends Texture {
	public function new(video:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class CompressedTexture extends Texture {
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter
import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int, count:Int };
	public var updateRanges:Array<{ start:Int, count:Int }>;
	public var gpuType:Int;
	public var version:Int;
	public var onUploadCallback:Void->Void = null;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.isOfType(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.usage = StaticDrawUsage;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.gpuType = FloatType;

		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
		}
	}

	public function get updateRange():{ offset:Int, count:Int } {
		WarnOnce.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;

		this.usage = source.usage;
		this.gpuType = source.gpuType;

		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;

		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		var _vector2 = new Vector2();
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			var _vector = new Vector3();
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}

		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) {
			value = MathUtils.denormalize(value, this.array);
		}
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) {
			value = MathUtils.normalize(value, this.array);
		}
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};

		if (this.name != "") {
			data.name = this.name;
		}
		if (this.usage != StaticDrawUsage) {
			data.usage = this.usage;
		}

		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var index:BufferAttribute;

	public function new() {
	}
}

class Geometry {
	public var vertices:Array<Vector3> = [];
	public var faces:Array<Dynamic> = [];

	public function new() {
	}
}

class Mesh {
	public var geometry:Geometry;
	public var material:Dynamic;

	public function new(geometry:Geometry, material:Dynamic) {
		this.geometry = geometry;
		this.material = material;
	}
}

class Scene {
	public var children:Array<Mesh> = [];
	public var background:Dynamic;

	public function new() {
	}

	public function addChild(mesh:Mesh) {
		children.push(mesh);
	}
}

class Renderer {
	public function new() {
	}

	public function render(scene:Scene, camera:Dynamic) {
	}
}

class Camera {
	public function new() {
	}
}

class WebGLRenderer extends Renderer {
	public function new() {
		super();
	}
}

class PerspectiveCamera extends Camera {
	public function new() {
		super();
	}
}

class BasicMaterial {
	public var color:Int;

	public function new(color:Int) {
		this.color = color;
	}
}

class ShaderMaterial {
	public var vertexShader:String;
	public var fragmentShader:String;
	public var uniforms:Map<String, Dynamic>;

	public function new(vertexShader:String, fragmentShader:String, uniforms:Map<String, Dynamic>) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.uniforms = uniforms;
	}
}

class Clock {
	public var time:Float;
	public var delta:Float;

	public function new() {
	}

	public function getDelta():Float {
		return delta;
	}

	public function getElapsedTime():Float {
		return time;
	}
}

class AnimationMixer {
	public function new() {
	}

	public function clipAction(clip:Dynamic):Dynamic {
		return null;
	}
}

class AnimationClip {
	public function new() {
	}
}

class AnimationAction {
	public var time:Float;

	public function new() {
	}

	public function play():Dynamic {
		return null;
	}

	public function stop():Dynamic {
		return null;
	}

	public function setTime(time:Float):Void {
		this.time = time;
	}

	public function setWeight(weight:Float):Void {
	}
}

class Object3D {
	public var position:Vector3;
	public var rotation:Vector3;
	public var scale:Vector3;
	public var children:Array<Object3D> = [];
	public var parent:Object3D;
	public var up:Vector3;

	public function new() {
		position = new Vector3();
		rotation = new Vector3();
		scale = new Vector3(1, 1, 1);
		up = new Vector3(0, 1, 0);
	}

	public function add(child:Object3D):Void {
		children.push(child);
		child.parent = this;
	}

	public function remove(child:Object3D):Void {
		var index = children.indexOf(child);
		if (index != -1) {
			children.splice(index, 1);
			child.parent = null;
		}
	}
}

class Group extends Object3D {
	public function new() {
		super();
	}
}

class SkinnedMesh extends Mesh {
	public var skeleton:Skeleton;

	public function new(geometry:Geometry, material:Dynamic, skeleton:Skeleton) {
		super(geometry, material);
		this.skeleton = skeleton;
	}
}

class Skeleton {
	public var bones:Array<Bone>;

	public function new(bones:Array<Bone>) {
		this.bones = bones;
	}
}

class Bone extends Object3D {
	public function new() {
		super();
	}
}

class BoxGeometry extends Geometry {
	public function new(width:Float, height:Float, depth:Float) {
		super();
		// ... BoxGeometry logic ...
	}
}

class SphereGeometry extends Geometry {
	public function new(radius:Float, widthSegments:Int, heightSegments:Int) {
		super();
		// ... SphereGeometry logic ...
	}
}

class PlaneGeometry extends Geometry {
	public function new(width:Float, height:Float) {
		super();
		// ... PlaneGeometry logic ...
	}
}

class CylinderGeometry extends Geometry {
	public function new(radiusTop:Float, radiusBottom:Float, height:Float, radialSegments:Int, heightSegments:Int, openEnded:Bool, thetaStart:Float, thetaLength:Float) {
		super();
		// ... CylinderGeometry logic ...
	}
}

class TorusGeometry extends Geometry {
	public function new(radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float) {
		super();
		// ... TorusGeometry logic ...
	}
}

class TorusKnotGeometry extends Geometry {
	public function new(radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int) {
		super();
		// ... TorusKnotGeometry logic ...
	}
}

class TextGeometry extends Geometry {
	public function new(text:String, parameters:Dynamic) {
		super();
		// ... TextGeometry logic ...
	}
}

class LineBasicMaterial extends BasicMaterial {
	public function new(color:Int) {
		super(color);
	}
}

class LineSegments extends Mesh {
	public function new(geometry:Geometry, material:LineBasicMaterial) {
		super(geometry, material);
	}
}

class Points extends Mesh {
	public function new(geometry:Geometry, material:Dynamic) {
		super(geometry, material);
	}
}

class PointsMaterial extends BasicMaterial {
	public var size:Float;

	public function new(color:Int, size:Float) {
		super(color);
		this.size = size;
	}
}

class Raycaster {
	public function new() {
	}

	public function intersectObject(object:Object3D, recursive:Bool = false):Array<Dynamic> {
		return [];
	}
}

class Vector4 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setHex(hex:Int):Void {
		this.r = ((hex >> 16) & 255) / 255;
		this.g = ((hex >> 8) & 255) / 255;
		this.b = (hex & 255) / 255;
	}

	public function getHex():Int {
		return ((r * 255) << 16) | ((g * 255) << 8) | (b * 255);
	}

	public function getStyle():String {
		return "rgb(" + Math.floor(r * 255) + "," + Math.floor(g * 255) + "," + Math.floor(b * 255) + ")";
	}
}

class Euler {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Quaternion {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Matrix3 {
	public function new() {
	}
}

class Matrix4 {
	public function new() {
	}
}

class AxesHelper extends Object3D {
	public function new(size:Float = 1) {
		super();
		// ... AxesHelper logic ...
	}
}

class GridHelper extends Object3D {
	public function new(size:Float, divisions:Int, color1:Color, color2:Color) {
		super();
		// ... GridHelper logic ...
	}
}

class DirectionalLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class AmbientLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class SpotLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
	}
}

class PointLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
	}
}

class HemisphereLight extends Object3D {
	public var color:Color;
	public var groundColor:Color;
	public var intensity:Float;

	public function new(color:Color, groundColor:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.groundColor = groundColor;
		this.intensity = intensity;
	}
}

class RectAreaLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var width:Float;
	public var height:Float;

	public function new(color:Color, intensity:Float, width:Float, height:Float) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.width = width;
		this.height = height;
	}
}

class LightHelper extends Object3D {
	public function new(light:Object3D, size:Float = 1) {
		super();
		// ... LightHelper logic ...
	}
}

class CameraHelper extends Object3D {
	public function new(camera:Camera, size:Float = 1) {
		super();
		// ... CameraHelper logic ...
	}
}

class SkeletonHelper extends Object3D {
	public function new(object:SkinnedMesh) {
		super();
		// ... SkeletonHelper logic ...
	}
}

class BoxHelper extends Object3D {
	public function new(object:Object3D, color:Color = null) {
		super();
		// ... BoxHelper logic ...
	}
}

class PlaneHelper extends Object3D {
	public function new(plane:Dynamic, size:Float, color:Color = null) {
		super();
		// ... PlaneHelper logic ...
	}
}

class ArrowHelper extends Object3D {
	public function new(dir:Vector3, origin:Vector3 = null, length:Float = 1, color:Color = null, headLength:Float = 0.2, headWidth:Float = 0.2) {
		super();
		// ... ArrowHelper logic ...
	}
}

class Sprite extends Object3D {
	public var material:Dynamic;

	public function new(material:Dynamic) {
		super();
		this.material = material;
	}
}

class SpriteMaterial extends BasicMaterial {
	public var map:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;

	public function new(parameters:Dynamic = null) {
		super(0xffffff);
		// ... SpriteMaterial logic ...
	}
}

class Texture {
	public function new(image:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
	}

	public function set needsUpdate(value:Bool) {
	}
}

class CanvasTexture extends Texture {
	public function new(canvas:Dynamic) {
		super(canvas);
	}
}

class DataTexture extends Texture {
	public var image:Dynamic;
	public var mapping:Dynamic;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;

	public function new(data:Dynamic, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, anisotropy:Int = null) {
		this.image = data;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
	}
}

class CubeTexture extends Texture {
	public function new(images:Array<Dynamic>, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class VideoTexture extends Texture {
	public function new(video:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class CompressedTexture extends Texture {
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter
import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int, count:Int };
	public var updateRanges:Array<{ start:Int, count:Int }>;
	public var gpuType:Int;
	public var version:Int;
	public var onUploadCallback:Void->Void = null;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.isOfType(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.usage = StaticDrawUsage;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.gpuType = FloatType;

		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
		}
	}

	public function get updateRange():{ offset:Int, count:Int } {
		WarnOnce.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;

		this.usage = source.usage;
		this.gpuType = source.gpuType;

		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;

		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		var _vector2 = new Vector2();
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			var _vector = new Vector3();
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}

		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) {
			value = MathUtils.denormalize(value, this.array);
		}
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) {
			value = MathUtils.normalize(value, this.array);
		}
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};

		if (this.name != "") {
			data.name = this.name;
		}
		if (this.usage != StaticDrawUsage) {
			data.usage = this.usage;
		}

		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var index:BufferAttribute;

	public function new() {
	}
}

class Geometry {
	public var vertices:Array<Vector3> = [];
	public var faces:Array<Dynamic> = [];

	public function new() {
	}
}

class Mesh {
	public var geometry:Geometry;
	public var material:Dynamic;

	public function new(geometry:Geometry, material:Dynamic) {
		this.geometry = geometry;
		this.material = material;
	}
}

class Scene {
	public var children:Array<Mesh> = [];
	public var background:Dynamic;

	public function new() {
	}

	public function addChild(mesh:Mesh) {
		children.push(mesh);
	}
}

class Renderer {
	public function new() {
	}

	public function render(scene:Scene, camera:Dynamic) {
	}
}

class Camera {
	public function new() {
	}
}

class WebGLRenderer extends Renderer {
	public function new() {
		super();
	}
}

class PerspectiveCamera extends Camera {
	public function new() {
		super();
	}
}

class BasicMaterial {
	public var color:Int;

	public function new(color:Int) {
		this.color = color;
	}
}

class ShaderMaterial {
	public var vertexShader:String;
	public var fragmentShader:String;
	public var uniforms:Map<String, Dynamic>;

	public function new(vertexShader:String, fragmentShader:String, uniforms:Map<String, Dynamic>) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.uniforms = uniforms;
	}
}

class Clock {
	public var time:Float;
	public var delta:Float;

	public function new() {
	}

	public function getDelta():Float {
		return delta;
	}

	public function getElapsedTime():Float {
		return time;
	}
}

class AnimationMixer {
	public function new() {
	}

	public function clipAction(clip:Dynamic):Dynamic {
		return null;
	}
}

class AnimationClip {
	public function new() {
	}
}

class AnimationAction {
	public var time:Float;

	public function new() {
	}

	public function play():Dynamic {
		return null;
	}

	public function stop():Dynamic {
		return null;
	}

	public function setTime(time:Float):Void {
		this.time = time;
	}

	public function setWeight(weight:Float):Void {
	}
}

class Object3D {
	public var position:Vector3;
	public var rotation:Vector3;
	public var scale:Vector3;
	public var children:Array<Object3D> = [];
	public var parent:Object3D;
	public var up:Vector3;

	public function new() {
		position = new Vector3();
		rotation = new Vector3();
		scale = new Vector3(1, 1, 1);
		up = new Vector3(0, 1, 0);
	}

	public function add(child:Object3D):Void {
		children.push(child);
		child.parent = this;
	}

	public function remove(child:Object3D):Void {
		var index = children.indexOf(child);
		if (index != -1) {
			children.splice(index, 1);
			child.parent = null;
		}
	}
}

class Group extends Object3D {
	public function new() {
		super();
	}
}

class SkinnedMesh extends Mesh {
	public var skeleton:Skeleton;

	public function new(geometry:Geometry, material:Dynamic, skeleton:Skeleton) {
		super(geometry, material);
		this.skeleton = skeleton;
	}
}

class Skeleton {
	public var bones:Array<Bone>;

	public function new(bones:Array<Bone>) {
		this.bones = bones;
	}
}

class Bone extends Object3D {
	public function new() {
		super();
	}
}

class BoxGeometry extends Geometry {
	public function new(width:Float, height:Float, depth:Float) {
		super();
		// ... BoxGeometry logic ...
	}
}

class SphereGeometry extends Geometry {
	public function new(radius:Float, widthSegments:Int, heightSegments:Int) {
		super();
		// ... SphereGeometry logic ...
	}
}

class PlaneGeometry extends Geometry {
	public function new(width:Float, height:Float) {
		super();
		// ... PlaneGeometry logic ...
	}
}

class CylinderGeometry extends Geometry {
	public function new(radiusTop:Float, radiusBottom:Float, height:Float, radialSegments:Int, heightSegments:Int, openEnded:Bool, thetaStart:Float, thetaLength:Float) {
		super();
		// ... CylinderGeometry logic ...
	}
}

class TorusGeometry extends Geometry {
	public function new(radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float) {
		super();
		// ... TorusGeometry logic ...
	}
}

class TorusKnotGeometry extends Geometry {
	public function new(radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int) {
		super();
		// ... TorusKnotGeometry logic ...
	}
}

class TextGeometry extends Geometry {
	public function new(text:String, parameters:Dynamic) {
		super();
		// ... TextGeometry logic ...
	}
}

class LineBasicMaterial extends BasicMaterial {
	public function new(color:Int) {
		super(color);
	}
}

class LineSegments extends Mesh {
	public function new(geometry:Geometry, material:LineBasicMaterial) {
		super(geometry, material);
	}
}

class Points extends Mesh {
	public function new(geometry:Geometry, material:Dynamic) {
		super(geometry, material);
	}
}

class PointsMaterial extends BasicMaterial {
	public var size:Float;

	public function new(color:Int, size:Float) {
		super(color);
		this.size = size;
	}
}

class Raycaster {
	public function new() {
	}

	public function intersectObject(object:Object3D, recursive:Bool = false):Array<Dynamic> {
		return [];
	}
}

class Vector4 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setHex(hex:Int):Void {
		this.r = ((hex >> 16) & 255) / 255;
		this.g = ((hex >> 8) & 255) / 255;
		this.b = (hex & 255) / 255;
	}

	public function getHex():Int {
		return ((r * 255) << 16) | ((g * 255) << 8) | (b * 255);
	}

	public function getStyle():String {
		return "rgb(" + Math.floor(r * 255) + "," + Math.floor(g * 255) + "," + Math.floor(b * 255) + ")";
	}
}

class Euler {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Quaternion {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Matrix3 {
	public function new() {
	}
}

class Matrix4 {
	public function new() {
	}
}

class AxesHelper extends Object3D {
	public function new(size:Float = 1) {
		super();
		// ... AxesHelper logic ...
	}
}

class GridHelper extends Object3D {
	public function new(size:Float, divisions:Int, color1:Color, color2:Color) {
		super();
		// ... GridHelper logic ...
	}
}

class DirectionalLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class AmbientLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class SpotLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
	}
}

class PointLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
	}
}

class HemisphereLight extends Object3D {
	public var color:Color;
	public var groundColor:Color;
	public var intensity:Float;

	public function new(color:Color, groundColor:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.groundColor = groundColor;
		this.intensity = intensity;
	}
}

class RectAreaLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var width:Float;
	public var height:Float;

	public function new(color:Color, intensity:Float, width:Float, height:Float) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.width = width;
		this.height = height;
	}
}

class LightHelper extends Object3D {
	public function new(light:Object3D, size:Float = 1) {
		super();
		// ... LightHelper logic ...
	}
}

class CameraHelper extends Object3D {
	public function new(camera:Camera, size:Float = 1) {
		super();
		// ... CameraHelper logic ...
	}
}

class SkeletonHelper extends Object3D {
	public function new(object:SkinnedMesh) {
		super();
		// ... SkeletonHelper logic ...
	}
}

class BoxHelper extends Object3D {
	public function new(object:Object3D, color:Color = null) {
		super();
		// ... BoxHelper logic ...
	}
}

class PlaneHelper extends Object3D {
	public function new(plane:Dynamic, size:Float, color:Color = null) {
		super();
		// ... PlaneHelper logic ...
	}
}

class ArrowHelper extends Object3D {
	public function new(dir:Vector3, origin:Vector3 = null, length:Float = 1, color:Color = null, headLength:Float = 0.2, headWidth:Float = 0.2) {
		super();
		// ... ArrowHelper logic ...
	}
}

class Sprite extends Object3D {
	public var material:Dynamic;

	public function new(material:Dynamic) {
		super();
		this.material = material;
	}
}

class SpriteMaterial extends BasicMaterial {
	public var map:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;

	public function new(parameters:Dynamic = null) {
		super(0xffffff);
		// ... SpriteMaterial logic ...
	}
}

class Texture {
	public function new(image:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
	}

	public function set needsUpdate(value:Bool) {
	}
}

class CanvasTexture extends Texture {
	public function new(canvas:Dynamic) {
		super(canvas);
	}
}

class DataTexture extends Texture {
	public var image:Dynamic;
	public var mapping:Dynamic;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;

	public function new(data:Dynamic, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, anisotropy:Int = null) {
		this.image = data;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
	}
}

class CubeTexture extends Texture {
	public function new(images:Array<Dynamic>, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class VideoTexture extends Texture {
	public function new(video:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class CompressedTexture extends Texture {
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter
import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int, count:Int };
	public var updateRanges:Array<{ start:Int, count:Int }>;
	public var gpuType:Int;
	public var version:Int;
	public var onUploadCallback:Void->Void = null;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.isOfType(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.usage = StaticDrawUsage;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.gpuType = FloatType;

		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
		}
	}

	public function get updateRange():{ offset:Int, count:Int } {
		WarnOnce.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;

		this.usage = source.usage;
		this.gpuType = source.gpuType;

		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;

		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		var _vector2 = new Vector2();
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			var _vector = new Vector3();
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}

		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) {
			value = MathUtils.denormalize(value, this.array);
		}
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) {
			value = MathUtils.normalize(value, this.array);
		}
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};

		if (this.name != "") {
			data.name = this.name;
		}
		if (this.usage != StaticDrawUsage) {
			data.usage = this.usage;
		}

		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var index:BufferAttribute;

	public function new() {
	}
}

class Geometry {
	public var vertices:Array<Vector3> = [];
	public var faces:Array<Dynamic> = [];

	public function new() {
	}
}

class Mesh {
	public var geometry:Geometry;
	public var material:Dynamic;

	public function new(geometry:Geometry, material:Dynamic) {
		this.geometry = geometry;
		this.material = material;
	}
}

class Scene {
	public var children:Array<Mesh> = [];
	public var background:Dynamic;

	public function new() {
	}

	public function addChild(mesh:Mesh) {
		children.push(mesh);
	}
}

class Renderer {
	public function new() {
	}

	public function render(scene:Scene, camera:Dynamic) {
	}
}

class Camera {
	public function new() {
	}
}

class WebGLRenderer extends Renderer {
	public function new() {
		super();
	}
}

class PerspectiveCamera extends Camera {
	public function new() {
		super();
	}
}

class BasicMaterial {
	public var color:Int;

	public function new(color:Int) {
		this.color = color;
	}
}

class ShaderMaterial {
	public var vertexShader:String;
	public var fragmentShader:String;
	public var uniforms:Map<String, Dynamic>;

	public function new(vertexShader:String, fragmentShader:String, uniforms:Map<String, Dynamic>) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.uniforms = uniforms;
	}
}

class Clock {
	public var time:Float;
	public var delta:Float;

	public function new() {
	}

	public function getDelta():Float {
		return delta;
	}

	public function getElapsedTime():Float {
		return time;
	}
}

class AnimationMixer {
	public function new() {
	}

	public function clipAction(clip:Dynamic):Dynamic {
		return null;
	}
}

class AnimationClip {
	public function new() {
	}
}

class AnimationAction {
	public var time:Float;

	public function new() {
	}

	public function play():Dynamic {
		return null;
	}

	public function stop():Dynamic {
		return null;
	}

	public function setTime(time:Float):Void {
		this.time = time;
	}

	public function setWeight(weight:Float):Void {
	}
}

class Object3D {
	public var position:Vector3;
	public var rotation:Vector3;
	public var scale:Vector3;
	public var children:Array<Object3D> = [];
	public var parent:Object3D;
	public var up:Vector3;

	public function new() {
		position = new Vector3();
		rotation = new Vector3();
		scale = new Vector3(1, 1, 1);
		up = new Vector3(0, 1, 0);
	}

	public function add(child:Object3D):Void {
		children.push(child);
		child.parent = this;
	}

	public function remove(child:Object3D):Void {
		var index = children.indexOf(child);
		if (index != -1) {
			children.splice(index, 1);
			child.parent = null;
		}
	}
}

class Group extends Object3D {
	public function new() {
		super();
	}
}

class SkinnedMesh extends Mesh {
	public var skeleton:Skeleton;

	public function new(geometry:Geometry, material:Dynamic, skeleton:Skeleton) {
		super(geometry, material);
		this.skeleton = skeleton;
	}
}

class Skeleton {
	public var bones:Array<Bone>;

	public function new(bones:Array<Bone>) {
		this.bones = bones;
	}
}

class Bone extends Object3D {
	public function new() {
		super();
	}
}

class BoxGeometry extends Geometry {
	public function new(width:Float, height:Float, depth:Float) {
		super();
		// ... BoxGeometry logic ...
	}
}

class SphereGeometry extends Geometry {
	public function new(radius:Float, widthSegments:Int, heightSegments:Int) {
		super();
		// ... SphereGeometry logic ...
	}
}

class PlaneGeometry extends Geometry {
	public function new(width:Float, height:Float) {
		super();
		// ... PlaneGeometry logic ...
	}
}

class CylinderGeometry extends Geometry {
	public function new(radiusTop:Float, radiusBottom:Float, height:Float, radialSegments:Int, heightSegments:Int, openEnded:Bool, thetaStart:Float, thetaLength:Float) {
		super();
		// ... CylinderGeometry logic ...
	}
}

class TorusGeometry extends Geometry {
	public function new(radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float) {
		super();
		// ... TorusGeometry logic ...
	}
}

class TorusKnotGeometry extends Geometry {
	public function new(radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int) {
		super();
		// ... TorusKnotGeometry logic ...
	}
}

class TextGeometry extends Geometry {
	public function new(text:String, parameters:Dynamic) {
		super();
		// ... TextGeometry logic ...
	}
}

class LineBasicMaterial extends BasicMaterial {
	public function new(color:Int) {
		super(color);
	}
}

class LineSegments extends Mesh {
	public function new(geometry:Geometry, material:LineBasicMaterial) {
		super(geometry, material);
	}
}

class Points extends Mesh {
	public function new(geometry:Geometry, material:Dynamic) {
		super(geometry, material);
	}
}

class PointsMaterial extends BasicMaterial {
	public var size:Float;

	public function new(color:Int, size:Float) {
		super(color);
		this.size = size;
	}
}

class Raycaster {
	public function new() {
	}

	public function intersectObject(object:Object3D, recursive:Bool = false):Array<Dynamic> {
		return [];
	}
}

class Vector4 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setHex(hex:Int):Void {
		this.r = ((hex >> 16) & 255) / 255;
		this.g = ((hex >> 8) & 255) / 255;
		this.b = (hex & 255) / 255;
	}

	public function getHex():Int {
		return ((r * 255) << 16) | ((g * 255) << 8) | (b * 255);
	}

	public function getStyle():String {
		return "rgb(" + Math.floor(r * 255) + "," + Math.floor(g * 255) + "," + Math.floor(b * 255) + ")";
	}
}

class Euler {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Quaternion {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Matrix3 {
	public function new() {
	}
}

class Matrix4 {
	public function new() {
	}
}

class AxesHelper extends Object3D {
	public function new(size:Float = 1) {
		super();
		// ... AxesHelper logic ...
	}
}

class GridHelper extends Object3D {
	public function new(size:Float, divisions:Int, color1:Color, color2:Color) {
		super();
		// ... GridHelper logic ...
	}
}

class DirectionalLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class AmbientLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class SpotLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
	}
}

class PointLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
	}
}

class HemisphereLight extends Object3D {
	public var color:Color;
	public var groundColor:Color;
	public var intensity:Float;

	public function new(color:Color, groundColor:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.groundColor = groundColor;
		this.intensity = intensity;
	}
}

class RectAreaLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var width:Float;
	public var height:Float;

	public function new(color:Color, intensity:Float, width:Float, height:Float) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.width = width;
		this.height = height;
	}
}

class LightHelper extends Object3D {
	public function new(light:Object3D, size:Float = 1) {
		super();
		// ... LightHelper logic ...
	}
}

class CameraHelper extends Object3D {
	public function new(camera:Camera, size:Float = 1) {
		super();
		// ... CameraHelper logic ...
	}
}

class SkeletonHelper extends Object3D {
	public function new(object:SkinnedMesh) {
		super();
		// ... SkeletonHelper logic ...
	}
}

class BoxHelper extends Object3D {
	public function new(object:Object3D, color:Color = null) {
		super();
		// ... BoxHelper logic ...
	}
}

class PlaneHelper extends Object3D {
	public function new(plane:Dynamic, size:Float, color:Color = null) {
		super();
		// ... PlaneHelper logic ...
	}
}

class ArrowHelper extends Object3D {
	public function new(dir:Vector3, origin:Vector3 = null, length:Float = 1, color:Color = null, headLength:Float = 0.2, headWidth:Float = 0.2) {
		super();
		// ... ArrowHelper logic ...
	}
}

class Sprite extends Object3D {
	public var material:Dynamic;

	public function new(material:Dynamic) {
		super();
		this.material = material;
	}
}

class SpriteMaterial extends BasicMaterial {
	public var map:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;

	public function new(parameters:Dynamic = null) {
		super(0xffffff);
		// ... SpriteMaterial logic ...
	}
}

class Texture {
	public function new(image:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
	}

	public function set needsUpdate(value:Bool) {
	}
}

class CanvasTexture extends Texture {
	public function new(canvas:Dynamic) {
		super(canvas);
	}
}

class DataTexture extends Texture {
	public var image:Dynamic;
	public var mapping:Dynamic;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;

	public function new(data:Dynamic, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, anisotropy:Int = null) {
		this.image = data;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
	}
}

class CubeTexture extends Texture {
	public function new(images:Array<Dynamic>, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class VideoTexture extends Texture {
	public function new(video:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class CompressedTexture extends Texture {
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter
import three.math.Vector3;
import three.math.Vector2;
import three.math.MathUtils;
import three.constants.StaticDrawUsage;
import three.constants.FloatType;
import three.extras.DataUtils;
import three.utils.WarnOnce;

class BufferAttribute {
	public var isBufferAttribute:Bool = true;
	public var name:String = "";
	public var array:Array<Float>;
	public var itemSize:Int;
	public var count:Int;
	public var normalized:Bool;
	public var usage:Int;
	public var _updateRange: { offset:Int, count:Int };
	public var updateRanges:Array<{ start:Int, count:Int }>;
	public var gpuType:Int;
	public var version:Int;
	public var onUploadCallback:Void->Void = null;

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		if (Std.isOfType(array, Array)) {
			throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");
		}

		this.array = array;
		this.itemSize = itemSize;
		this.count = array != null ? array.length / itemSize : 0;
		this.normalized = normalized;

		this.usage = StaticDrawUsage;
		this._updateRange = { offset: 0, count: -1 };
		this.updateRanges = [];
		this.gpuType = FloatType;

		this.version = 0;
	}

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
		}
	}

	public function get updateRange():{ offset:Int, count:Int } {
		WarnOnce.warnOnce("THREE.BufferAttribute: updateRange() is deprecated and will be removed in r169. Use addUpdateRange() instead.");
		return this._updateRange;
	}

	public function setUsage(value:Int):BufferAttribute {
		this.usage = value;
		return this;
	}

	public function addUpdateRange(start:Int, count:Int):Void {
		this.updateRanges.push({ start: start, count: count });
	}

	public function clearUpdateRanges():Void {
		this.updateRanges = [];
	}

	public function copy(source:BufferAttribute):BufferAttribute {
		this.name = source.name;
		this.array = new source.array.constructor(source.array);
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;

		this.usage = source.usage;
		this.gpuType = source.gpuType;

		return this;
	}

	public function copyAt(index1:Int, attribute:BufferAttribute, index2:Int):BufferAttribute {
		index1 *= this.itemSize;
		index2 *= attribute.itemSize;

		for (i in 0...this.itemSize) {
			this.array[index1 + i] = attribute.array[index2 + i];
		}

		return this;
	}

	public function copyArray(array:Array<Float>):BufferAttribute {
		this.array.set(array);
		return this;
	}

	public function applyMatrix3(m:three.math.Matrix3):BufferAttribute {
		var _vector2 = new Vector2();
		if (this.itemSize == 2) {
			for (i in 0...this.count) {
				_vector2.fromBufferAttribute(this, i);
				_vector2.applyMatrix3(m);
				this.setXY(i, _vector2.x, _vector2.y);
			}
		} else if (this.itemSize == 3) {
			var _vector = new Vector3();
			for (i in 0...this.count) {
				_vector.fromBufferAttribute(this, i);
				_vector.applyMatrix3(m);
				this.setXYZ(i, _vector.x, _vector.y, _vector.z);
			}
		}

		return this;
	}

	public function applyMatrix4(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyMatrix4(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function applyNormalMatrix(m:three.math.Matrix3):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.applyNormalMatrix(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function transformDirection(m:three.math.Matrix4):BufferAttribute {
		var _vector = new Vector3();
		for (i in 0...this.count) {
			_vector.fromBufferAttribute(this, i);
			_vector.transformDirection(m);
			this.setXYZ(i, _vector.x, _vector.y, _vector.z);
		}

		return this;
	}

	public function set(value:Array<Float>, offset:Int = 0):BufferAttribute {
		this.array.set(value, offset);
		return this;
	}

	public function getComponent(index:Int, component:Int):Float {
		var value = this.array[index * this.itemSize + component];
		if (this.normalized) {
			value = MathUtils.denormalize(value, this.array);
		}
		return value;
	}

	public function setComponent(index:Int, component:Int, value:Float):BufferAttribute {
		if (this.normalized) {
			value = MathUtils.normalize(value, this.array);
		}
		this.array[index * this.itemSize + component] = value;
		return this;
	}

	public function getX(index:Int):Float {
		var x = this.array[index * this.itemSize];
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = x;
		return this;
	}

	public function getY(index:Int):Float {
		var y = this.array[index * this.itemSize + 1];
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = y;
		return this;
	}

	public function getZ(index:Int):Float {
		var z = this.array[index * this.itemSize + 2];
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = z;
		return this;
	}

	public function getW(index:Int):Float {
		var w = this.array[index * this.itemSize + 3];
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = w;
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = x;
		this.array[index + 1] = y;
		this.array[index + 2] = z;
		this.array[index + 3] = w;
		return this;
	}

	public function onUpload(callback:Void->Void):BufferAttribute {
		this.onUploadCallback = callback;
		return this;
	}

	public function clone():BufferAttribute {
		return new BufferAttribute(this.array, this.itemSize).copy(this);
	}

	public function toJSON():Dynamic {
		var data = {
			itemSize: this.itemSize,
			type: this.array.constructor.name,
			array: this.array.copy(),
			normalized: this.normalized
		};

		if (this.name != "") {
			data.name = this.name;
		}
		if (this.usage != StaticDrawUsage) {
			data.usage = this.usage;
		}

		return data;
	}
}

class Int8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int8Array(array), itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8Array(array), itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint8ClampedArray(array), itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int16Array(array), itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Int32Array(array), itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint32Array(array), itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public var isFloat16BufferAttribute:Bool = true;

	public function new(array:Array<Int>, itemSize:Int, normalized:Bool = false) {
		super(new Uint16Array(array), itemSize, normalized);
	}

	public function getX(index:Int):Float {
		var x = DataUtils.fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) {
			x = MathUtils.denormalize(x, this.array);
		}
		return x;
	}

	public function setX(index:Int, x:Float):BufferAttribute {
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
		}
		this.array[index * this.itemSize] = DataUtils.toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) {
			y = MathUtils.denormalize(y, this.array);
		}
		return y;
	}

	public function setY(index:Int, y:Float):BufferAttribute {
		if (this.normalized) {
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index * this.itemSize + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) {
			z = MathUtils.denormalize(z, this.array);
		}
		return z;
	}

	public function setZ(index:Int, z:Float):BufferAttribute {
		if (this.normalized) {
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index * this.itemSize + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = DataUtils.fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) {
			w = MathUtils.denormalize(w, this.array);
		}
		return w;
	}

	public function setW(index:Int, w:Float):BufferAttribute {
		if (this.normalized) {
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index * this.itemSize + 3] = DataUtils.toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = MathUtils.normalize(x, this.array);
			y = MathUtils.normalize(y, this.array);
			z = MathUtils.normalize(z, this.array);
			w = MathUtils.normalize(w, this.array);
		}
		this.array[index + 0] = DataUtils.toHalfFloat(x);
		this.array[index + 1] = DataUtils.toHalfFloat(y);
		this.array[index + 2] = DataUtils.toHalfFloat(z);
		this.array[index + 3] = DataUtils.toHalfFloat(w);
		return this;
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new(array:Array<Float>, itemSize:Int, normalized:Bool = false) {
		super(new Float32Array(array), itemSize, normalized);
	}
}

class BufferGeometry {
	public var attributes:Map<String, BufferAttribute> = new Map();
	public var index:BufferAttribute;

	public function new() {
	}
}

class Geometry {
	public var vertices:Array<Vector3> = [];
	public var faces:Array<Dynamic> = [];

	public function new() {
	}
}

class Mesh {
	public var geometry:Geometry;
	public var material:Dynamic;

	public function new(geometry:Geometry, material:Dynamic) {
		this.geometry = geometry;
		this.material = material;
	}
}

class Scene {
	public var children:Array<Mesh> = [];
	public var background:Dynamic;

	public function new() {
	}

	public function addChild(mesh:Mesh) {
		children.push(mesh);
	}
}

class Renderer {
	public function new() {
	}

	public function render(scene:Scene, camera:Dynamic) {
	}
}

class Camera {
	public function new() {
	}
}

class WebGLRenderer extends Renderer {
	public function new() {
		super();
	}
}

class PerspectiveCamera extends Camera {
	public function new() {
		super();
	}
}

class BasicMaterial {
	public var color:Int;

	public function new(color:Int) {
		this.color = color;
	}
}

class ShaderMaterial {
	public var vertexShader:String;
	public var fragmentShader:String;
	public var uniforms:Map<String, Dynamic>;

	public function new(vertexShader:String, fragmentShader:String, uniforms:Map<String, Dynamic>) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.uniforms = uniforms;
	}
}

class Clock {
	public var time:Float;
	public var delta:Float;

	public function new() {
	}

	public function getDelta():Float {
		return delta;
	}

	public function getElapsedTime():Float {
		return time;
	}
}

class AnimationMixer {
	public function new() {
	}

	public function clipAction(clip:Dynamic):Dynamic {
		return null;
	}
}

class AnimationClip {
	public function new() {
	}
}

class AnimationAction {
	public var time:Float;

	public function new() {
	}

	public function play():Dynamic {
		return null;
	}

	public function stop():Dynamic {
		return null;
	}

	public function setTime(time:Float):Void {
		this.time = time;
	}

	public function setWeight(weight:Float):Void {
	}
}

class Object3D {
	public var position:Vector3;
	public var rotation:Vector3;
	public var scale:Vector3;
	public var children:Array<Object3D> = [];
	public var parent:Object3D;
	public var up:Vector3;

	public function new() {
		position = new Vector3();
		rotation = new Vector3();
		scale = new Vector3(1, 1, 1);
		up = new Vector3(0, 1, 0);
	}

	public function add(child:Object3D):Void {
		children.push(child);
		child.parent = this;
	}

	public function remove(child:Object3D):Void {
		var index = children.indexOf(child);
		if (index != -1) {
			children.splice(index, 1);
			child.parent = null;
		}
	}
}

class Group extends Object3D {
	public function new() {
		super();
	}
}

class SkinnedMesh extends Mesh {
	public var skeleton:Skeleton;

	public function new(geometry:Geometry, material:Dynamic, skeleton:Skeleton) {
		super(geometry, material);
		this.skeleton = skeleton;
	}
}

class Skeleton {
	public var bones:Array<Bone>;

	public function new(bones:Array<Bone>) {
		this.bones = bones;
	}
}

class Bone extends Object3D {
	public function new() {
		super();
	}
}

class BoxGeometry extends Geometry {
	public function new(width:Float, height:Float, depth:Float) {
		super();
		// ... BoxGeometry logic ...
	}
}

class SphereGeometry extends Geometry {
	public function new(radius:Float, widthSegments:Int, heightSegments:Int) {
		super();
		// ... SphereGeometry logic ...
	}
}

class PlaneGeometry extends Geometry {
	public function new(width:Float, height:Float) {
		super();
		// ... PlaneGeometry logic ...
	}
}

class CylinderGeometry extends Geometry {
	public function new(radiusTop:Float, radiusBottom:Float, height:Float, radialSegments:Int, heightSegments:Int, openEnded:Bool, thetaStart:Float, thetaLength:Float) {
		super();
		// ... CylinderGeometry logic ...
	}
}

class TorusGeometry extends Geometry {
	public function new(radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float) {
		super();
		// ... TorusGeometry logic ...
	}
}

class TorusKnotGeometry extends Geometry {
	public function new(radius:Float, tube:Float, tubularSegments:Int, radialSegments:Int, p:Int, q:Int) {
		super();
		// ... TorusKnotGeometry logic ...
	}
}

class TextGeometry extends Geometry {
	public function new(text:String, parameters:Dynamic) {
		super();
		// ... TextGeometry logic ...
	}
}

class LineBasicMaterial extends BasicMaterial {
	public function new(color:Int) {
		super(color);
	}
}

class LineSegments extends Mesh {
	public function new(geometry:Geometry, material:LineBasicMaterial) {
		super(geometry, material);
	}
}

class Points extends Mesh {
	public function new(geometry:Geometry, material:Dynamic) {
		super(geometry, material);
	}
}

class PointsMaterial extends BasicMaterial {
	public var size:Float;

	public function new(color:Int, size:Float) {
		super(color);
		this.size = size;
	}
}

class Raycaster {
	public function new() {
	}

	public function intersectObject(object:Object3D, recursive:Bool = false):Array<Dynamic> {
		return [];
	}
}

class Vector4 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setHex(hex:Int):Void {
		this.r = ((hex >> 16) & 255) / 255;
		this.g = ((hex >> 8) & 255) / 255;
		this.b = (hex & 255) / 255;
	}

	public function getHex():Int {
		return ((r * 255) << 16) | ((g * 255) << 8) | (b * 255);
	}

	public function getStyle():String {
		return "rgb(" + Math.floor(r * 255) + "," + Math.floor(g * 255) + "," + Math.floor(b * 255) + ")";
	}
}

class Euler {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}

class Quaternion {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
}

class Matrix3 {
	public function new() {
	}
}

class Matrix4 {
	public function new() {
	}
}

class AxesHelper extends Object3D {
	public function new(size:Float = 1) {
		super();
		// ... AxesHelper logic ...
	}
}

class GridHelper extends Object3D {
	public function new(size:Float, divisions:Int, color1:Color, color2:Color) {
		super();
		// ... GridHelper logic ...
	}
}

class DirectionalLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class AmbientLight extends Object3D {
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}
}

class SpotLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;
	public var angle:Float;
	public var penumbra:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
		this.angle = angle;
		this.penumbra = penumbra;
	}
}

class PointLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var distance:Float;

	public function new(color:Color, intensity:Float = 1, distance:Float = 0) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.distance = distance;
	}
}

class HemisphereLight extends Object3D {
	public var color:Color;
	public var groundColor:Color;
	public var intensity:Float;

	public function new(color:Color, groundColor:Color, intensity:Float = 1) {
		super();
		this.color = color;
		this.groundColor = groundColor;
		this.intensity = intensity;
	}
}

class RectAreaLight extends Object3D {
	public var color:Color;
	public var intensity:Float;
	public var width:Float;
	public var height:Float;

	public function new(color:Color, intensity:Float, width:Float, height:Float) {
		super();
		this.color = color;
		this.intensity = intensity;
		this.width = width;
		this.height = height;
	}
}

class LightHelper extends Object3D {
	public function new(light:Object3D, size:Float = 1) {
		super();
		// ... LightHelper logic ...
	}
}

class CameraHelper extends Object3D {
	public function new(camera:Camera, size:Float = 1) {
		super();
		// ... CameraHelper logic ...
	}
}

class SkeletonHelper extends Object3D {
	public function new(object:SkinnedMesh) {
		super();
		// ... SkeletonHelper logic ...
	}
}

class BoxHelper extends Object3D {
	public function new(object:Object3D, color:Color = null) {
		super();
		// ... BoxHelper logic ...
	}
}

class PlaneHelper extends Object3D {
	public function new(plane:Dynamic, size:Float, color:Color = null) {
		super();
		// ... PlaneHelper logic ...
	}
}

class ArrowHelper extends Object3D {
	public function new(dir:Vector3, origin:Vector3 = null, length:Float = 1, color:Color = null, headLength:Float = 0.2, headWidth:Float = 0.2) {
		super();
		// ... ArrowHelper logic ...
	}
}

class Sprite extends Object3D {
	public var material:Dynamic;

	public function new(material:Dynamic) {
		super();
		this.material = material;
	}
}

class SpriteMaterial extends BasicMaterial {
	public var map:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;

	public function new(parameters:Dynamic = null) {
		super(0xffffff);
		// ... SpriteMaterial logic ...
	}
}

class Texture {
	public function new(image:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
	}

	public function set needsUpdate(value:Bool) {
	}
}

class CanvasTexture extends Texture {
	public function new(canvas:Dynamic) {
		super(canvas);
	}
}

class DataTexture extends Texture {
	public var image:Dynamic;
	public var mapping:Dynamic;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;

	public function new(data:Dynamic, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, anisotropy:Int = null) {
		this.image = data;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
	}
}

class CubeTexture extends Texture {
	public function new(images:Array<Dynamic>, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class VideoTexture extends Texture {
	public function new(video:Dynamic, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter:Int = null, format:Int = null, type:Int = null, anisotropy:Int = null) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
	}
}

class CompressedTexture extends Texture {
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Dynamic = null, wrapS:Int = null, wrapT:Int = null, magFilter:Int = null, minFilter