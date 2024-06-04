class Face {

	public var a:Dynamic;
	public var b:Dynamic;
	public var c:Dynamic;
	public var normal:Vector3;

	public function new(a:Dynamic, b:Dynamic, c:Dynamic) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.normal = new Vector3();
	}

}