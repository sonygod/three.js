@:generic
class three(Type) {
	public function new() {}
}

class three.core {
	public class DataTextureLoader {
		public function new(manager:Dynamic) {}
		public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic;
		public function loadAsync(url:String, onProgress:Dynamic):Future<Dynamic>;
	}
}

class three.textures {
	public class RGBAFormat {}
	public class LinearFilter {}
	public class CubeTexture {
		public function new() {}
	}
	public class HalfFloatType {}
	public class DataUtils {
		public static function toHalfFloat(v:Float):Int;
	}
}
```

Finally, you'll need to include the hxThree library in your haxelib. If you don't have it yet, install it using haxelib: