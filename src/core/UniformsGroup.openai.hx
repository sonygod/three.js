package three.core;

import haxe.ds.Array;
import three.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
    public var isUniformsGroup:Bool = true;

    static var _id:Int = 0;

    public var id:Int = _id++;

    public var name:String = '';

    public var usage:Int = StaticDrawUsage;
    public var uniforms:Array<Dynamic> = [];

    public function new() {
        super();
    }

    public function add(uniform:Dynamic):UniformsGroup {
        uniforms.push(uniform);
        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index:Int = uniforms.indexOf(uniform);
        if (index != -1) uniforms.splice(index, 1);
        return this;
    }

    public function setName(name:String):UniformsGroup {
        this.name = name;
        return this;
    }

    public function setUsage(value:Int):UniformsGroup {
        this.usage = value;
        return this;
    }

    public function dispose():UniformsGroup {
        dispatchEvent({ type: 'dispose' });
        return this;
    }

    public function copy(source:UniformsGroup):UniformsGroup {
        name = source.name;
        usage = source.usage;

        var uniformsSource:Array<Dynamic> = source.uniforms;
        uniforms = [];

        for (i in 0...uniformsSource.length) {
            var uniforms:Array<Dynamic> = uniformsSource[i] is Array ? uniformsSource[i] : [uniformsSource[i]];
            for (j in 0...uniforms.length) {
                uniforms.push(uniforms[j].clone());
            }
        }

        return this;
    }

    public function clone():UniformsGroup {
        return new UniformsGroup().copy(this);
    }
}