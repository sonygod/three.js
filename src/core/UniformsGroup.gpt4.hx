import EventDispatcher;
import StaticDrawUsage;

class UniformsGroup extends EventDispatcher {

    public var isUniformsGroup:Bool = true;
    @:isVar private static var _id:Int = 0;
    @:isVar public var id:Int;
    public var name:String;
    public var usage:Int;
    public var uniforms:Array<Dynamic>;

    public function new() {
        super();
        this.id = _id++;
        this.name = '';
        this.usage = StaticDrawUsage;
        this.uniforms = [];
    }

    public function add(uniform:Dynamic):UniformsGroup {
        this.uniforms.push(uniform);
        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index:Int = this.uniforms.indexOf(uniform);
        if (index != -1) this.uniforms.splice(index, 1);
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
        this.dispatchEvent({ type: 'dispose' });
        return this;
    }

    public function copy(source:UniformsGroup):UniformsGroup {
        this.name = source.name;
        this.usage = source.usage;
        this.uniforms = [];
        for (i in 0...source.uniforms.length) {
            var uniformsSource = source.uniforms[i];
            var uniforms = Std.is(uniformsSource, Array) ? uniformsSource : [uniformsSource];
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