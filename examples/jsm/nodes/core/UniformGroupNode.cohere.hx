import Node from './Node.hx';

class UniformGroupNode extends Node {
    public var name:String;
    public var version:Int;
    public var shared:Bool;

    public function new(name:String, shared:Bool = false) {
        super('string');
        this.name = name;
        this.version = 0;
        this.shared = shared;
    }

    public function set_needsUpdate(value:Bool) {
        if (value) {
            version++;
        }
    }
}

function uniformGroup(name:String):UniformGroupNode {
    return new UniformGroupNode(name);
}

function sharedUniformGroup(name:String):UniformGroupNode {
    return new UniformGroupNode(name, true);
}

var frameGroup = sharedUniformGroup('frame');
var renderGroup = sharedUniformGroup('render');
var objectGroup = uniformGroup('object');

class export {
    static public function __init__() {
        Node.addNodeClass('UniformGroupNode', UniformGroupNode);
    }
}