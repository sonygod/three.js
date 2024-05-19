class Composite {

	public function new(targetGroup:Dynamic, path:String, optionalParsedPath:Dynamic = null) {

		var parsedPath = optionalParsedPath ? optionalParsedPath : PropertyBinding.parseTrackName(path);

		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, parsedPath);

	}

	public function getValue(array:Array<Dynamic>, offset:Int) {

		this.bind(); // bind all binding

		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding = this._bindings[firstValidIndex];

		// and only call .getValue on the first
		if (binding !== undefined) binding.getValue(array, offset);

	}

	public function setValue(array:Array<Dynamic>, offset:Int) {

		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].setValue(array, offset);

		}

	}

	public function bind() {

		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].bind();

		}

	}

	public function unbind() {

		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {

			bindings[i].unbind();

		}

	}

}