class GLTFExporter {

	var pluginCallbacks:Array<Dynamic->GLTFExtension>;

	public function new() {

		pluginCallbacks = [];

		register(function(writer) {
			return cast writer.GLTFLightExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsUnlitExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsTransmissionExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsVolumeExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsIorExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsSpecularExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsClearcoatExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsDispersionExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsIridescenceExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsSheenExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsAnisotropyExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsEmissiveStrengthExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMaterialsBumpExtension(writer);
		});

		register(function(writer) {
			return cast writer.GLTFMeshGpuInstancing(writer);
		});

	}

	public function register(callback:Dynamic->GLTFExtension):GLTFExporter {

		if (pluginCallbacks.indexOf(callback) == -1) {
			pluginCallbacks.push(callback);
		}

		return this;

	}

	public function unregister(callback:Dynamic->GLTFExtension):GLTFExporter {

		if (pluginCallbacks.indexOf(callback) != -1) {
			pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
		}

		return this;

	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  input   Scene or Array of THREE.Scenes
	 * @param  onDone  Callback on completed
	 * @param  onError  Callback on errors
	 * @param  options options
	 */
	public function parse(input:Dynamic, onDone:Dynamic->Void, onError:Dynamic->Void, options:Dynamic):Void {

		var writer = new GLTFWriter();
		var plugins = [];

		for (i in pluginCallbacks) {
			plugins.push(pluginCallbacks[i](writer));
		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);

	}

	public function parseAsync(input:Dynamic, options:Dynamic):Promise<Void> {

		var scope = this;

		return new Promise(function(resolve, reject) {
			scope.parse(input, resolve, reject, options);
		});

	}

}