class GLTFExporter {

	public var pluginCallbacks:Array<Dynamic->Dynamic>;

	public function new() {
		this.pluginCallbacks = new Array<Dynamic->Dynamic>();

		this.register(function(writer:Dynamic) {
			return new GLTFLightExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsUnlitExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsTransmissionExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsVolumeExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsIorExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsSpecularExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsClearcoatExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsDispersionExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsIridescenceExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsSheenExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsAnisotropyExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsEmissiveStrengthExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMaterialsBumpExtension(writer);
		});

		this.register(function(writer:Dynamic) {
			return new GLTFMeshGpuInstancing(writer);
		});
	}

	public function register(callback:Dynamic->Dynamic):GLTFExporter {
		if (this.pluginCallbacks.indexOf(callback) == -1) {
			this.pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback:Dynamic->Dynamic):GLTFExporter {
		if (this.pluginCallbacks.indexOf(callback) != -1) {
			this.pluginCallbacks.splice(this.pluginCallbacks.indexOf(callback), 1);
		}
		return this;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Function} onError  Callback on errors
	 * @param  {Object} options options
	 */
	public function parse(input:Dynamic, onDone:Dynamic->Void, onError:Dynamic->Void, options:Dynamic):Void {
		var writer = new GLTFWriter();
		var plugins:Array<Dynamic> = new Array<Dynamic>();

		for (i in 0...this.pluginCallbacks.length) {
			plugins.push(this.pluginCallbacks[i](writer));
		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input:Dynamic, options:Dynamic):Dynamic {
		var scope = this;
		return new Promise(function(resolve, reject) {
			scope.parse(input, resolve, reject, options);
		});
	}
}