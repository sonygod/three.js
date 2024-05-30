package three.js.nodes.core;

import three.js.nodes.Node;

class UniformGroupNode extends Node {
    public var name:String;
    public var version:Int = 0;
    public var shared:Bool;
    public var isUniformGroup:Bool = true;

    public function new(name:String, ?shared:Bool = false) {
        super('string');
        this.name = name;
        this.shared = shared;
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value) version++;
    }
}

inline function uniformGroup(name:String):UniformGroupNode {
    return new UniformGroupNode(name);
}

inline function sharedUniformGroup(name:String):UniformGroupNode {
    return new UniformGroupNode(name, true);
}

inline var frameGroup:UniformGroupNode = sharedUniformGroup('frame');
inline var renderGroup:UniformGroupNode = sharedUniformGroup('render');
inline var objectGroup:UniformGroupNode = uniformGroup('object');

addNodeClass('UniformGroupNode', UniformGroupNode);