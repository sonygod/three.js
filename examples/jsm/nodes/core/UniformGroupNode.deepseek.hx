import Node from './Node.hx';
import { addNodeClass } from './Node.hx';

class UniformGroupNode extends Node {

	public function new(name:String, ?shared:Bool = false) {
		super('string');

		this.name = name;
		this.version = 0;

		this.shared = shared;

		this.isUniformGroup = true;
	}

	public function set needsUpdate(value:Bool) {
		if (value == true) this.version++;
	}

}

static function uniformGroup(name:String) {
	return new UniformGroupNode(name);
}

static function sharedUniformGroup(name:String) {
	return new UniformGroupNode(name, true);
}

static var frameGroup = sharedUniformGroup('frame');
static var renderGroup = sharedUniformGroup('render');
static var objectGroup = uniformGroup('object');

addNodeClass('UniformGroupNode', UniformGroupNode);