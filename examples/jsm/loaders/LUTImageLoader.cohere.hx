package;

import js.Browser.Document;
import js.Browser.HtmlCanvasElement;
import js.Browser.ImageData;
import js.Browser.Window;
import js.three.Data3DTexture;
import js.three.Loader;
import js.three.RGBAFormat;
import js.three.TextureLoader;
import js.three.UnsignedByteType;
import js.three.ClampToEdgeWrapping;
import js.three.LinearFilter;

class LUTImageLoader extends Loader {
    var flip: Bool;

    public function new(flipVertical = false) {
        super();
        flip = flipVertical;
    }

    public function load(url: String, onLoad: Dynamic, onProgress: Dynamic, onError: Dynamic) {
        var loader = new TextureLoader();
        loader.crossOrigin = crossOrigin;
        loader.path = path;
        loader.load(url, function(texture) {
            try {
                var imageData = getImageData(texture);
                onLoad(parse(imageData.data, Std.int(Math.min(texture.image.width, texture.image.height))));
            } catch (e: Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function getImageData(texture) : ImageData {
        var width = texture.image.width;
        var height = texture.image.height;
        var canvas = Window.document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        var context = canvas.getContext2d();

        if (flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }

        context.drawImage(texture.image, 0, 0);
        return context.getImageData(0, 0, width, height);
    }

    function horz2Vert(texture) : ImageData {
        var width = texture.image.height;
        var height = texture.image.width;
        var canvas = Window.document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        var context = canvas.getContext2d();

        if (flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }

        var i: Int;
        for (i = 0; i < width; i++) {
            var sy = i * width;
            var dy = (flip) ? height - i * width : i * width;
            context.drawImage(texture.image, sy, 0, width, width, 0, dy, width, width);
        }

        return context.getImageData(0, 0, width, height);
    }

    function parse(dataArray: Array<Int>, size: Int) {
        var data = new Uint8Array(dataArray);
        var texture3D = new Data3DTexture();
        texture3D.image.data = data;
        texture3D.image.width = size;
        texture3D.image.height = size;
        texture3D.image.depth = size;
        texture3D.format = RGBAFormat;
        texture3D.type = UnsignedByteType;
        texture3D.magFilter = LinearFilter;
        texture3D.minFilter = LinearFilter;
        texture3D.wrapS = ClampToEdgeWrapping;
        texture3D.wrapT = ClampToEdgeWrapping;
        texture3D.wrapR = ClampToEdgeWrapping;
        texture3D.generateMipmaps = false;
        texture3D.needsUpdate = true;
        return { size: size, texture3D: texture3D };
    }
}