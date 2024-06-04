class GLTFExporter {

	public var pluginCallbacks:Array<GLTFWriter->Dynamic>;

	public function new() {
		this.pluginCallbacks = [];

		this.register(function(writer:GLTFWriter) return new GLTFLightExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsUnlitExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsTransmissionExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsVolumeExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsIorExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsSpecularExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsClearcoatExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsDispersionExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsIridescenceExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsSheenExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsAnisotropyExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsEmissiveStrengthExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMaterialsBumpExtension(writer));
		this.register(function(writer:GLTFWriter) return new GLTFMeshGpuInstancing(writer));
	}

	public function register(callback:GLTFWriter->Dynamic):GLTFExporter {
		if (this.pluginCallbacks.indexOf(callback) == -1) {
			this.pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback:GLTFWriter->Dynamic):GLTFExporter {
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
		var plugins:Array<Dynamic> = [];
		for (i in 0...this.pluginCallbacks.length) {
			plugins.push(this.pluginCallbacks[i](writer));
		}
		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input:Dynamic, options:Dynamic):Promise<Dynamic> {
		return new Promise(function(resolve, reject) {
			this.parse(input, resolve, reject, options);
		});
	}

}