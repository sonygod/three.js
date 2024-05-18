import Vector3 from '../math/Vector3.hx';
import Vector2 from '../math/Vector2.hx';
import Box3 from '../math/Box3.hx';
import EventDispatcher from './EventDispatcher.hx';
import BufferAttribute from './BufferAttribute.hx';
import Sphere from '../math/Sphere.hx';
import Object3D from './Object3D.hx';
import Matrix4 from '../math/Matrix4.hx';
import Matrix3 from '../math/Matrix3.hx';
import MathUtils from '../math/MathUtils.hx';
import arrayNeedsUint32 from '../utils.hx';

class BufferGeometry extends EventDispatcher {

	public var id:Int;
	public var uuid:String;
	public var name:String;
	public var type:String;
	public var index:BufferAttribute<Float>;
	public var attributes:Dict<String, BufferAttribute<Float>>;
	public var morphAttributes:Dict<String, Array<BufferAttribute<Float>>>;
	public var morphTargetsRelative:Bool;
	public var groups:Array<{start:Int, count:Int, materialIndex:Int}>;
	public var boundingBox:Box3;
	public var boundingSphere:Sphere;
	public var drawRange: {start:Int, count:Int};
	public var userData:Dynamic;

	public function new() {
		super();
		this.isBufferGeometry = true;
		this.id = _id++;
		this.uuid = MathUtils.generateUUID();
		this.name = '';
		this.type = 'BufferGeometry';
		this.index = null;
		this.attributes = {};
		this.morphAttributes = {};
		this.morphTargetsRelative = false;
		this.groups = [];
		this.boundingBox = null;
		this.boundingSphere = null;
		this.drawRange = { start: 0, count: Int.MAX_VALUE };
		this.userData = {};
	}

	public function getIndex():BufferAttribute<Float> {
		return this.index;
	}

	public function setIndex(index:Array<Float>):BufferGeometry {
		if (Array.isArray(index)) {
			if (arrayNeedsUint32(index)) {
				this.index = new Uint32BufferAttribute(index, 1);
			} else {
				this.index = new Uint16BufferAttribute(index, 1);
			}
		} else {
			this.index = index;
		}
		return this;
	}

	public function getAttribute(name:String):BufferAttribute<Float> {
		return this.attributes[name];
	}

	public function setAttribute(name:String, attribute:BufferAttribute<Float>):BufferGeometry {
		this.attributes[name] = attribute;
		return this;
	}

	public function deleteAttribute(name:String):BufferGeometry {
		delete this.attributes[name];
		return this;
	}

	public function hasAttribute(name:String):Bool {
		return this.attributes[name] !== undefined;
	}

	// ... continue implementing the other functions

}