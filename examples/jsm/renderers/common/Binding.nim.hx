class Binding {
    public var name:String;
    public var visibility:Int;

    public function new(name:String = "") {
        this.name = name;
        this.visibility = 0;
    }

    public function setVisibility(visibility:Int):Void {
        this.visibility |= visibility;
    }

    public function clone():Binding {
        var binding = Type.createEmptyInstance(Type.getClass(this));
        Reflect.copyFields(this, binding);
        return binding;
    }
}