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