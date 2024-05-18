package three.js.examples.jsm.nodes.core;

import Node;

class UniformGroupNode extends Node {
    
    public var name:String;
    public var version:Int;
    public var shared:Bool;
    public var isUniformGroup:Bool;

    public function new(name:String, shared:Bool = false) {
        super('string');
        this.name = name;
        this.version = 0;
        this.shared = shared;
        this.isUniformGroup = true;
    }

    private function set_needsUpdate(value:Bool):Void {
        if (value) this.version++;
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

Node.addNodeClass('UniformGroupNode', UniformGroupNode);