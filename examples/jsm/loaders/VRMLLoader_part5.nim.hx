class Face {

	var a;
	var b;
	var c;
	var normal:Vector3;

	public function new(a:Dynamic, b:Dynamic, c:Dynamic) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.normal = Vector3.createEmpty();
	}

}