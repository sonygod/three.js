import three.math.Quaternion;
import three.math.Matrix4;
import three.math.MathUtils;

class Euler {
    public static var DEFAULT_ORDER:String = "XYZ";

    private var _matrix:Matrix4 = new Matrix4();
    private var _quaternion:Quaternion = new Quaternion();

    public var isEuler:Bool = true;
    private var _x:Float;
    private var _y:Float;
    private var _z:Float;
    private var _order:String;
    private var _onChangeCallback:Dynamic;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, order:String = Euler.DEFAULT_ORDER) {
        this._x = x;
        this._y = y;
        this._z = z;
        this._order = order;
    }

    public function get_x():Float {
        return this._x;
    }

    public function set_x(value:Float):Float {
        this._x = value;
        this._onChangeCallback();
        return this._x;
    }

    // Similar getters and setters for _y and _z

    public function get_order():String {
        return this._order;
    }

    public function set_order(value:String):String {
        this._order = value;
        this._onChangeCallback();
        return this._order;
    }

    public function set(x:Float, y:Float, z:Float, order:String = null):Euler {
        this._x = x;
        this._y = y;
        this._z = z;
        this._order = order != null ? order : this._order;
        this._onChangeCallback();
        return this;
    }

    public function clone():Euler {
        return new Euler(this._x, this._y, this._z, this._order);
    }

    public function copy(euler:Euler):Euler {
        this._x = euler._x;
        this._y = euler._y;
        this._z = euler._z;
        this._order = euler._order;
        this._onChangeCallback();
        return this;
    }

    public function setFromRotationMatrix(m:Matrix4, order:String = null, update:Bool = true):Euler {
        // ... implementation
        return this;
    }

    public function setFromQuaternion(q:Quaternion, order:String = null, update:Bool = true):Euler {
        this._matrix.makeRotationFromQuaternion(q);
        return this.setFromRotationMatrix(this._matrix, order, update);
    }

    public function setFromVector3(v:Vector3, order:String = null):Euler {
        return this.set(v.x, v.y, v.z, order);
    }

    public function reorder(newOrder:String):Euler {
        this._quaternion.setFromEuler(this);
        return this.setFromQuaternion(this._quaternion, newOrder);
    }

    public function equals(euler:Euler):Bool {
        return euler._x == this._x && euler._y == this._y && euler._z == this._z && euler._order == this._order;
    }

    public function fromArray(array:Array<Float>):Euler {
        this._x = array[0];
        this._y = array[1];
        this._z = array[2];
        if (array.length > 3) this._order = array[3];
        this._onChangeCallback();
        return this;
    }

    public function toArray(array:Array<Dynamic> = null, offset:Int = 0):Array<Dynamic> {
        if (array == null) array = [];
        array[offset] = this._x;
        array[offset + 1] = this._y;
        array[offset + 2] = this._z;
        array[offset + 3] = this._order;
        return array;
    }

    public function _onChange(callback:Dynamic):Euler {
        this._onChangeCallback = callback;
        return this;
    }

    public function _onChangeCallback():Void { }
}