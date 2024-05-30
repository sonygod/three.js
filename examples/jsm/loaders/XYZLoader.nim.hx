import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;

class XYZLoader extends Loader {

	public function new() {
		super();
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {

		var scope = this;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text:String) {

			try {

				onLoad(scope.parse(text));

			} catch (e:Dynamic) {

				if (onError != null) {

					onError(e);

				} else {

					Sys.println(e);

				}

				scope.manager.itemError(url);

			}

		}, onProgress, onError);

	}

	public function parse(text:String) {

		var lines = text.split('\n');

		var vertices = [];
		var colors = [];
		var color = new Color();

		for (line in lines) {

			line = line.trim();

			if (line.charAt(0) == '#') continue; // skip comments

			var lineValues = line.split(/\s+/);

			if (lineValues.length == 3) {

				// XYZ

				vertices.push(Std.parseFloat(lineValues[0]));
				vertices.push(Std.parseFloat(lineValues[1]));
				vertices.push(Std.parseFloat(lineValues[2]));

			}

			if (lineValues.length == 6) {

				// XYZRGB

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
		geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

		if (colors.length > 0) {

			geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

		}

		return geometry;

	}

}