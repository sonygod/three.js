package three.js.examples.jsm.renderers.common;

class Binding {
    public var name:String;
    public var visibility:Int;

    public function new(?name:String = '') {
        this.name = name;
        this.visibility = 0;
    }

    public function setVisibility(visibility:Int) {
        this.visibility |= visibility;
    }

    public function clone():Binding {
        var clone:Binding = Type.createInstance(Type.getClass(this), []);
        for (field in Reflect.fields(this)) {
            Reflect.setField(clone, field, Reflect.field(this, field));
        }
        return clone;
    }
}