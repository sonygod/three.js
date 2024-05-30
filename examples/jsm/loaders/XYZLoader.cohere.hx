import haxe.io.Bytes;

class XYZLoader {
	public function load(url:String, onLoad:Bytes->Void, onProgress:Float->Void, onError:Dynamic->Void):Void {
		var loader = new haxe.io.BytesLoader();
		loader.setOnLoad(function(bytes:Bytes) {
			try {
				onLoad(bytes);
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
			}
		});
		loader.setOnError(onError);
		loader.load(url);
	}

	public function parse(text:String):BufferGeometry {
		var lines = text.split('\n');
		var vertices = [];
		var colors = [];
		var color = new Color();

		for (line in lines) {
			line = line.trim();
			if (line.charAt(0) == '#') continue; // skip comments

			var lineValues = line.split( /\s+/ );

			if (lineValues.length == 3) {
				// XYZ
				vertices.push( Std.parseFloat(lineValues[0]) );
				vertices.push( Std.parseFloat(lineValues[1]) );
				vertices.push( Std.parseFloat(lineValues[2]) );
			} else if (lineValues.length == 6) {
				// XYZRGB
				vertices.push( Std.parseFloat(lineValues[0]) );
				vertices.push( Std.parseFloat(lineValues[1]) );
				vertices.push( Std.parseFloat(lineValues[2]) );

				var r = Std.parseFloat(lineValues[3]) / 255;
				var g = Std.parseFloat(lineValues[4]) / 255;
				var b = Std.parseFloat(lineValues[5]) / 255;

				color.setRGB(r, g, b);
				colors.push( color.r, color.g, color.b );
			}
		}

		var geometry = new BufferGeometry();
		geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

		if (colors.length > 0) {
			geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));
		}

		return geometry;
	}
}

class Color {
	public var r:Float;
	public var g:Float;
	public var b:Float;

	public function new(r:Float = 0, g:Float = 0, b:Float = 0) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	public function setRGB(r:Float, g:Float, b:Float):Void {
		this.r = r;
		this.g = g;
		this.b = b;
	}
}

class BufferGeometry {
	public function setAttribute(name:String, attribute:Float32BufferAttribute):Void {
		// ...
	}
}

class Float32BufferAttribute {
	public function new(data:Array<Float>, itemSize:Int):Void {
		// ...
	}
}