class Vector4 {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    public function new( x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1 ) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function get_width():Float {
        return z;
    }

    public function set_width( value:Float ):Void {
        z = value;
    }

    public function get_height():Float {
        return w;
    }

    public function set_height( value:Float ):Void {
        w = value;
    }

    public function set( x:Float, y:Float, z:Float, w:Float ):Vector4 {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
        return this;
    }

    // ... (其他成员函数和属性的实现)

    // 注意：由于 Haxe 和 JavaScript 在语法上有很多不同，以上代码只是简单地将 JavaScript 代码转换为 Haxe 代码。
    // 实际上，可能还需要对代码进行进一步的调整，以确保它在 Haxe 环境中正确运行。

}

// 注意：在 Haxe 中，我们通常不需要将类导出为模块。如果需要将 Vector4 类作为模块使用，可以使用 @:module 注解。