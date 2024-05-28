package;

import js.EventDispatcher;
import js.StaticDrawUsage;

class UniformsGroup extends EventDispatcher {
    public var id:Int;
    public var name:String;
    public var usage:StaticDrawUsage;
    public var uniforms:Array<Dynamic>;

    public function new() {
        super();
        id = _id++;
        name = '';
        usage = StaticDrawUsage.StaticDraw;
        uniforms = [];
    }

    public function add(uniform:Dynamic):UniformsGroup {
        uniforms.push(uniform);
        return this;
    }

    public function remove(uniform:Dynamic):UniformsGroup {
        var index = uniforms.indexOf(uniform);
        if (index != -1) uniforms.splice(index, 1);
        return this;
    }

    public function setName(name:String):UniformsGroup {
        this.name = name;
        return this;
    }

    public function setUsage(value:StaticDrawUsage):UniformsGroup {
        usage = value;
        return this;
    }

    public function dispose():UniformsGroup {
        dispatchEvent(js.Browser.createEvent('Events', 'Event', ['dispose']));
        return this;
    }

    public function copy(source:UniformsGroup):UniformsGroup {
        name = source.name;
        usage = source.usage;
        var uniformsSource = source.uniforms;
        uniforms = [];
        for (uniform in uniformsSource) {
            var uniforms = uniformsSource[uniform];
            if (Reflect.isArray(uniforms)) {
                for (var uniformData in uniforms) {
                    uniforms.push(uniformData.clone());
                }
            } else {
                uniforms.push(uniforms.clone());
            }
        }
        return this;
    }

    public function clone():UniformsGroup {
        return new UniformsGroup().copy(this);
    }
}

var _id:Int = 0;

class Reflect {
    public static function isArray(obj:Dynamic):Bool;
}

class js {
    public static class Browser {
        public static function createEvent(type:String, eventInitDict:Dynamic = null):Dynamic;
    }

    public static class EventDispatcher {
        public function new();
        public function dispatchEvent(event:Dynamic):Bool;
    }

    public static class StaticDrawUsage {
        public static var StaticDraw:StaticDrawUsage;
    }
}