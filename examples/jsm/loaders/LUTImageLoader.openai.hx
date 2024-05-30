package three.js/examples/loaders;

import three.Loader;
import three.TextureLoader;
import three.Data3DTexture;
import three.RGBAFormat;
import three.UnsignedByteType;
import three.ClampToEdgeWrapping;
import three.LinearFilter;

class LUTImageLoader extends Loader {

    var flip:Bool;

    public function new(flipVertical:Bool = false) {
        super();
        flip = flipVertical;
    }

    override function load(url:String, onLoad:Dynamic->Void, onProgress:Float->Void, onError:Dynamic->Void) {
        var loader = new TextureLoader(manager);
        loader.setCrossOrigin(crossOrigin);
        loader.setPath(path);
        loader.load(url, function(texture) {
            try {
                var imageData:ImageData;
                if (texture.image.width < texture.image.height) {
                    imageData = getImageData(texture);
                } else {
                    imageData = horz2Vert(texture);
                }
                onLoad(parse(imageData.data, Math.min(texture.image.width, texture.image.height)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function getImageData(texture:Texture):ImageData {
        var width = texture.image.width;
        var height = texture.image.height;
        var canvas = js.html.CanvasElement.create(width, height);
        var context = canvas.getContext2d();
        if (flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }
        context.drawImage(texture.image, 0, 0);
        return context.getImageData(0, 0, width, height);
    }

    function horz2Vert(texture:Texture):ImageData {
        var width = texture.image.height;
        var height = texture.image.width;
        var canvas = js.html.CanvasElement.create(width, height);
        var context = canvas.getContext2d();
        if (flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }
        for (i in 0...width) {
            var sy = i * width;
            var dy = (flip) ? height - i * width : i * width;
            context.drawImage(texture.image, sy, 0, width, width, 0, dy, width, width);
        }
        return context.getImageData(0, 0, width, height);
    }

    function parse(dataArray:Array<UInt>, size:Int):{ size:Int, texture3D:Data3DTexture } {
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