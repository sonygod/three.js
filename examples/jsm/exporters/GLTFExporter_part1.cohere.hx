class GLTFExporter {
	public var pluginCallbacks: Array<GLTFPluginCallback> = [];

	public function new() {
		this.register(function(writer: GLTFWriter): GLTFPlugin -> {
			return GLTFLightExtension(writer);
		});

		this.register(function(writer: GLTFWriter): GLTFPlugin -> {
			return GLTFMaterialsUnlitExtension(writer);
		});

		// ... 其他注册回调 ...

		// 注册其他 GLTFPlugin 回调

	}

	public function register(callback: GLTFPluginCallback): GLTFExporter {
		if (pluginCallbacks.indexOf(callback) == -1) {
			pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback: GLTFPluginCallback): GLTFExporter {
		if (pluginCallbacks.indexOf(callback) != -1) {
			pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
		}
		return this;
	}

	public function parse(input: Dynamic, onDone: GLTFParseCallback, ?onError: GLTFErrorCallback, ?options: GLTFWriterOptions): Void {
		var writer = GLTFWriter();
		var plugins = [];

		for (plugin in pluginCallbacks) {
			plugins.push(pluginCallbacks[plugin](writer));
		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options);
	}

	public function parseAsync(input: Dynamic, ?options: GLTFWriterOptions): Promise<Void> {
		var scope = this;
		return Promise.make(function(resolve, reject) {
			scope.parse(input, resolve, reject, options);
		});
	}
}

typedef GLTFPluginCallback = GLTFPlugin->Function;
typedef GLTFParseCallback = Void->Function;
typedef GLTFErrorCallback = Dynamic->Function;

class GLTFWriter {
	public function write(input: Dynamic, onDone: GLTFParseCallback, ?options: GLTFWriterOptions): Void {
		// 实现 GLTFWriter 的写入逻辑
	}

	public function setPlugins(plugins: Array<GLTFPlugin>): Void {
		// 为 GLTFWriter 设置插件
	}
}

typedef GLTFPlugin = Abstract{};

class GLTFLightExtension extends GLTFPlugin {
	public function new(writer: GLTFWriter) {
		super();
		// 实现 GLTFLightExtension 逻辑
	}
}

class GLTFMaterialsUnlitExtension extends GLTFPlugin {
	public function new(writer: GLTFWriter) {
		super();
		// 实现 GLTFMaterialsUnlitExtension 逻辑
	}
}

// ... 其他 GLTFPlugin 实现 ...

// 实现其他 GLTFPlugin 类