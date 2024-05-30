import Node from './Node.js';
import { addNodeClass } from './Node.js';

class UniformGroupNode extends Node {

	public var name:String;
	public var version:Int;
	public var shared:Bool;

	public var isUniformGroup:Bool = true;

	public function new(name:String, shared:Bool = false) {
		super('string');

		this.name = name;
		this.version = 0;

		this.shared = shared;
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version++;
	}

	public static function uniformGroup(name:String):UniformGroupNode {
		return new UniformGroupNode(name);
	}

	public static function sharedUniformGroup(name:String):UniformGroupNode {
		return new UniformGroupNode(name, true);
	}

	public static var frameGroup:UniformGroupNode = sharedUniformGroup('frame');
	public static var renderGroup:UniformGroupNode = sharedUniformGroup('render');
	public static var objectGroup:UniformGroupNode = uniformGroup('object');

}

addNodeClass('UniformGroupNode', UniformGroupNode);

export default UniformGroupNode;
export var uniformGroup:(name:String) -> UniformGroupNode;
export var sharedUniformGroup:(name:String) -> UniformGroupNode;
export var frameGroup:UniformGroupNode;
export var renderGroup:UniformGroupNode;
export var objectGroup:UniformGroupNode;