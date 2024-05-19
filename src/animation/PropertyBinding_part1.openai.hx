class Composite {

	var _targetGroup:TargetGroup;
	var _bindings:Array<Binding>;

	public function new(targetGroup:TargetGroup, path:String, optionalParsedPath:OptionalParsedPath = null) {
		
		var parsedPath = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);
		
		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe(path, parsedPath);

	}

	public function getValue(array:Array<Float>, offset:Int):Void {

		this.bind(); // bind all bindings

		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding:Binding = this._bindings[firstValidIndex];

		// and only call .getValue on the first
		if (binding != null) binding.getValue(array, offset);

	}

	public function setValue(array:Array<Float>, offset:Int):Void {

		var bindings:Array<Binding> = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].setValue(array, offset);

		}

	}

	public function bind():Void {

		var bindings:Array<Binding> = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].bind();

		}

	}

	public function unbind():Void {

		var bindings:Array<Binding> = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].unbind();

		}

	}

}