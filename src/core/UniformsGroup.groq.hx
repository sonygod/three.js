package three.js.src.core;

import three.js.src.core.EventDispatcher;

class UniformsGroup extends EventDispatcher {
    public var isUniformsGroup:Bool = true;
    public var id:Int;
    public var name:String;
    public var usage:StaticDrawUsage;
    public var uniforms:Array<Dynamic>;

    private static var _id:Int = 0;

    public function new() {
        super();
        id = _id++;
        name = '';
        usage = StaticDrawUsage;
        uniforms = [];
    }

    public function add(uniform:Dynamic):UniformsGroup {
        uniforms.push(uniform);
        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index:Int = uniforms.indexOf(uniform);
        if (index != -1) {
            uniforms.splice(index, 1);
        }
        return this;
    }

    public function setName(name:String):UniformsGroup {
        this.name = name;
        return this;
    }

    public function setUsage(value:StaticDrawUsage):UniformsGroup {
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
        uniforms.resize(0);
        for (i in 0...uniformsSource.length) {
            var uniforms:Array<Dynamic> = uniformsSource[i];
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