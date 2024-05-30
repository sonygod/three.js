class GLTFExporter {

	var pluginCallbacks:Array<Dynamic>;

	public function new() {

		this.pluginCallbacks = [];

		this.register( function(writer) {

			return new GLTFLightExtension(writer);

		} );

		this.register( function(writer) {

			return new GLTFMaterialsUnlitExtension(writer);

		} );

		// ... continue with the rest of the register calls

	}

	public function register(callback:Dynamic):GLTFExporter {

		if (this.pluginCallbacks.indexOf(callback) == -1) {

			this.pluginCallbacks.push(callback);

		}

		return this;

	}

	public function unregister(callback:Dynamic):GLTFExporter {

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
	public function parse(input:Dynamic, onDone:Dynamic, onError:Dynamic, options:Dynamic):Void {

		var writer = new GLTFWriter();
		var plugins:Array<Dynamic> = [];

		for (i in 0...this.pluginCallbacks.length) {

			plugins.push(this.pluginCallbacks[i](writer));

		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);

	}

	public function parseAsync(input:Dynamic, options:Dynamic):Promise<Void> {

		var scope = this;

		return new Promise(function(resolve:Dynamic, reject:Dynamic) {

			scope.parse(input, resolve, reject, options);

		});

	}

}