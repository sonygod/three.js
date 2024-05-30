import three.core.EventDispatcher;
import three.constants.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {

    public var isUniformsGroup:Bool;
    public var id:Int;
    public var name:String;
    public var usage:Dynamic; // Adjust the type based on the actual type of StaticDrawUsage
    public var uniforms:Array<Dynamic>; // Adjust the type based on the actual type of uniforms

    private static var _id:Int = 0;

    public function new() {
        super();
        this.isUniformsGroup = true;
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
        if (index != -1) {
            this.uniforms.splice(index, 1);
        }
        return this;
    }

    public function setName(name:String):UniformsGroup {
        this.name = name;
        return this;
    }

    public function setUsage(value:Dynamic):UniformsGroup {
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

        var uniformsSource:Array<Dynamic> = source.uniforms;

        this.uniforms = [];

        for (i in 0...uniformsSource.length) {
            var uniformList = if (Std.is(uniformsSource[i], Array)) cast uniformsSource[i] else [uniformsSource[i]];
            for (uniform in uniformList) {
                this.uniforms.push(uniform.clone());
            }
        }

        return this;
    }

    public function clone():UniformsGroup {
        return new UniformsGroup().copy(this);
    }

    public static function main() {
        // This is just a main method to prevent Haxe errors due to no entry point
    }
}