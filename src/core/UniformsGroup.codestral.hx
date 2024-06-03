import three.core.EventDispatcher;
import three.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
    public var isUniformsGroup:Bool = true;
    public var id:Int;
    public var name:String = "";
    public var usage:Int = StaticDrawUsage;
    public var uniforms:Array<Dynamic> = [];

    private static var _id:Int = 0;

    public function new() {
        super();

        this.id = _id++;
    }

    public function add(uniform:Dynamic):UniformsGroup {
        this.uniforms.push(uniform);

        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index:Int = this.uniforms.indexOf(uniform);

        if (index !== -1) this.uniforms.splice(index, 1);

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
        this.dispatchEvent({type: 'dispose'});

        return this;
    }

    public function copy(source:UniformsGroup):UniformsGroup {
        this.name = source.name;
        this.usage = source.usage;

        var uniformsSource:Array<Dynamic> = source.uniforms;

        this.uniforms.length = 0;

        for (i in 0...uniformsSource.length) {
            var uniforms:Array<Dynamic> = Array.isArray(uniformsSource[i]) ? uniformsSource[i] : [uniformsSource[i]];

            for (j in 0...uniforms.length) {
                this.uniforms.push(uniforms[j].clone());
            }
        }

        return this;
    }

    public function clone():UniformsGroup {
        return new UniformsGroup().copy(this);
    }
}