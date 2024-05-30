class Vector2 {
    public var x:Float;
    public var y:Float;

    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }
}

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

class MathConstants {
    static var x:Int = 2;
    static var y:Int = 3;
    static var z:Int = 4;
    static var w:Int = 5;

    static var negInf2:Vector2 = new Vector2(-Infinity, -Infinity);
    static var posInf2:Vector2 = new Vector2(Infinity, Infinity);

    static var negOne2:Vector2 = new Vector2(-1, -1);
    static var zero2:Vector2 = new Vector2();
    static var one2:Vector2 = new Vector2(1, 1);
    static var two2:Vector2 = new Vector2(2, 2);

    static var negInf3:Vector3 = new Vector3(-Infinity, -Infinity, -Infinity);
    static var posInf3:Vector3 = new Vector3(Infinity, Infinity, Infinity);

    static var zero3:Vector3 = new Vector3();
    static var one3:Vector3 = new Vector3(1, 1, 1);
    static var two3:Vector3 = new Vector3(2, 2, 2);

    static var eps:Float = 0.0001;
}