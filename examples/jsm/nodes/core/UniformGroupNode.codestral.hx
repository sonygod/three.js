import Node from './Node';
import NodeUtils from './NodeUtils';

class UniformGroupNode extends Node {

    public var name: String;
    public var version: Int;
    public var shared: Bool;
    public var isUniformGroup: Bool = true;

    public function new(name: String, shared: Bool = false) {
        super('string');
        this.name = name;
        this.version = 0;
        this.shared = shared;
    }

    public function set_needsUpdate(value: Bool): Void {
        if (value) this.version++;
    }
}

function uniformGroup(name: String): UniformGroupNode {
    return new UniformGroupNode(name);
}

function sharedUniformGroup(name: String): UniformGroupNode {
    return new UniformGroupNode(name, true);
}

var frameGroup: UniformGroupNode = sharedUniformGroup('frame');
var renderGroup: UniformGroupNode = sharedUniformGroup('render');
var objectGroup: UniformGroupNode = uniformGroup('object');

NodeUtils.addNodeClass('UniformGroupNode', UniformGroupNode);