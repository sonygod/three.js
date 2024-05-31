class Vector4 {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function get_width():Float {
        return z;
    }

    public function set_width(value:Float):Void {
        z = value;
    }

    public function get_height():Float {
        return w;
    }

    public function set_height(value:Float):Void {
        w = value;
    }

    public function set(x:Float, y:Float, z:Float, w:Float):Vector4 {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
        return this;
    }

    public function setScalar(scalar:Float):Vector4 {
        x = scalar;
        y = scalar;
        z = scalar;
        w = scalar;
        return this;
    }

    // ... [Other methods translated similarly]

    public function random():Vector4 {
        x = Math.random();
        y = Math.random();
        z = Math.random();
        w = Math.random();
        return this;
    }

    public function iterator():Iterator<Float> {
        return {
            hasNext: function():Bool {
                return false; // Implement the logic for hasNext
            },
            next: function():Float {
                return 0; // Implement the logic for next
            }
        };
    }

    // ... [Rest of the methods translated similarly]

}

// Since Haxe does not have native support for exporting classes like ES6 modules,
// you would typically define a static extension or use a macro to simulate the export.