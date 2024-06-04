import three.core.BufferGeometry;
import three.math.Color;
import three.loaders.Loader;
import three.core.Float32BufferAttribute;
import three.loaders.FileLoader;

class XYZLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) : Void {
		var scope = this;
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(text:String) : BufferGeometry {
		var lines = text.split("\n");
		var vertices:Array<Float> = [];
		var colors:Array<Float> = [];
		var color = new Color();
		for (line in lines) {
			line = line.trim();
			if (line.charAt(0) == "#") continue;
			var lineValues = line.split(/\s+/);
			if (lineValues.length == 3) {
				vertices.push(Std.parseFloat(lineValues[0]));
				vertices.push(Std.parseFloat(lineValues[1]));
				vertices.push(Std.parseFloat(lineValues[2]));
			}
			if (lineValues.length == 6) {
				vertices.push(Std.parseFloat(lineValues[0]));
				vertices.push(Std.parseFloat(lineValues[1]));
				vertices.push(Std.parseFloat(lineValues[2]));
				var r = Std.parseFloat(lineValues[3]) / 255;
				var g = Std.parseFloat(lineValues[4]) / 255;
				var b = Std.parseFloat(lineValues[5]) / 255;
				color.set(r, g, b).convertSRGBToLinear();
				colors.push(color.r, color.g, color.b);
			}
		}
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		if (colors.length > 0) {
			geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));
		}
		return geometry;
	}
}