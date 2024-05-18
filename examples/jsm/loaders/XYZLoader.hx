package three.examples.jm.loaders;

import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;

class XYZLoader extends Loader {
    public function new() {
        super();
    }

    public function load(url:String, onLoad:(geometry:BufferGeometry)->Void, onProgress:(progress:Float)->Void, onError:(error:Dynamic)->Void) {
        var scope:XYZLoader = this;
        var loader:FileLoader = new FileLoader(this.manager);
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
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(text:String):BufferGeometry {
        var lines:Array<String> = text.split("\n");
        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];
        var color:Color = new Color();

        for (line in lines) {
            line = StringTools.trim(line);
            if (line.charAt(0) == '#') continue; // skip comments

            var lineValues:Array<String> = line.split(~/\s+/);
            if (lineValues.length == 3) {
                // XYZ
                vertices.push(Std.parseFloat(lineValues[0]));
                vertices.push(Std.parseFloat(lineValues[1]));
                vertices.push(Std.parseFloat(lineValues[2]));
            } else if (lineValues.length == 6) {
                // XYZRGB
                vertices.push(Std.parseFloat(lineValues[0]));
                vertices.push(Std.parseFloat(lineValues[1]));
                vertices.push(Std.parseFloat(lineValues[2]));

                var r:Float = Std.parseFloat(lineValues[3]) / 255;
                var g:Float = Std.parseFloat(lineValues[4]) / 255;
                var b:Float = Std.parseFloat(lineValues[5]) / 255;

                color.setRGB(r, g, b).convertSRGBToLinear();

                colors.push(color.r, color.g, color.b);
            }
        }

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

        if (colors.length > 0) {
            geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));
        }

        return geometry;
    }
}