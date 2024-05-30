import three.js.src.core.EventDispatcher;
import three.js.src.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
    private static var _id:Int = 0;

    public var isUniformsGroup:Bool = true;
    public var id:Int;
    public var name:String;
    public var usage:StaticDrawUsage;
    public var uniforms:Array<Dynamic>;

    public function new() {
        super();

        this.id = _id++;

        this.name = '';

        this.usage = StaticDrawUsage.Static;
        this.uniforms = [];
    }

    public function add(uniform:Dynamic):UniformsGroup {
        this.uniforms.push(uniform);

        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index = this.uniforms.indexOf(uniform);

        if (index != -1) this.uniforms.splice(index, 1);

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
        this.dispatchEvent(new Event('dispose'));

        return this;
    }

    public function copy(source:UniformsGroup):UniformsGroup {
        this.name = source.name;
        this.usage = source.usage;

        this.uniforms.length = 0;

        for (i in 0...source.uniforms.length) {
            var uniforms = Std.is(source.uniforms[i], Array) ? source.uniforms[i] : [source.uniforms[i]];

            for (j in 0...uniforms.length) {
                this.uniforms.push(uniforms[j].clone());
            }
        }

        return this;
    }

    public function clone():UniformsGroup {
        return Type.createEmptyInstance(Type.getClass(this)).copy(this);
    }
}