class Face {

    public var a:Int;
    public var b:Int;
    public var c:Int;
    public var normal:Vector3;

    public function new(a:Int, b:Int, c:Int) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.normal = new Vector3();
    }
}

Note:
In Haxe, classes and their members are declared with the `class` and `var` keywords, respectively. The `public` keyword is used to make the members accessible outside of the class. The `new` keyword is used to define a constructor in Haxe.

Haxe uses the `Vector3` class from the `hx3d` library for 3D vectors, which you would need to import at the beginning of your file:


import hx3d.Vector3;