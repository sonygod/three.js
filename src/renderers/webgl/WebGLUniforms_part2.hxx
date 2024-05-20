class PureArrayUniform {

	var id:String;
	var addr:Int;
	var cache:Array<Dynamic>;
	var type:String;
	var size:Int;
	var setValue:Dynamic;

	public function new(id:String, activeInfo:Dynamic, addr:Int) {
		this.id = id;
		this.addr = addr;
		this.cache = [];
		this.type = activeInfo.type;
		this.size = activeInfo.size;
		this.setValue = getPureArraySetter(activeInfo.type);

		// this.path = activeInfo.name; // DEBUG
	}

}