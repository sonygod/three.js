// Assuming MathUtils.hx is a separate file with static methods
import MathUtils;

class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    public function get_width():Float {
        return x;
    }

    public function set_width(value:Float):Void {
        x = value;
    }

    public function get_height():Float {
        return y;
    }

    public function set_height(value:Float):Void {
        y = value;
    }

    public function set(x:Float, y:Float):Vector2 {
        this.x = x;
        this.y = y;
        return this;
    }

    public function setScalar(scalar:Float):Vector2 {
        this.x = scalar;
        this.y = scalar;
        return this;
    }

    public function setX(x:Float):Vector2 {
        this.x = x;
        return this;
    }

    public function setY(y:Float):Vector2 {
        this.y = y;
        return this;
    }

    public function setComponent(index:Int, value:Float):Vector2 {
        switch (index) {
            case 0: this.x = value; break;
            case 1: this.y = value; break;
            default: throw new Error('index is out of range: $index');
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0: return this.x;
            case 1: return this.y;
            default: throw new Error('index is out of range: $index');
        }
    }

    public function clone():Vector2 {
        return new Vector2(this.x, this.y);
    }

    public function copy(v:Vector2):Vector2 {
        this.x = v.x;
        this.y = v.y;
        return this;
    }

    // ... Other methods translated similarly

    // Note: The iterator method in JavaScript using Symbol.iterator
    // does not have a direct equivalent in Haxe. You can use an
    // Array or Iterable instead, or create a custom iterator structure.

    // ... Rest of the methods translated similarly
}

// Usage:
// var vector = new Vector2(10, 20);
// trace(vector.get_width()); // Prints 10
// vector.set_width(30);
// trace(vector.get_width()); // Prints 30