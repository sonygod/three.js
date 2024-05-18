package three.js.examples.jsm.loaders;

import three.Loader;
import three.TextureLoader;
import three.Data3DTexture;
import three.RGBAFormat;
import three.UnsignedByteType;
import three.ClampToEdgeWrapping;
import three.LinearFilter;

class LUTImageLoader extends Loader {
    public var flip:Bool;

    public function new(flipVertical:Bool = false) {
        super();
        this.flip = flipVertical;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var loader:TextureLoader = new TextureLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);
        loader.load(url, function(texture:Dynamic) {
            try {
                var imageData:Dynamic;
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
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function getImageData(texture:Dynamic):Dynamic {
        var width:Int = texture.image.width;
        var height:Int = texture.image.height;
        var canvas:js.html.CanvasElement = js.Browser.document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        var context:js.html.CanvasRenderingContext2D = canvas.getContext("2d");
        if (this.flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }
        context.drawImage(texture.image, 0, 0);
        return context.getImageData(0, 0, width, height);
    }

    private function horz2Vert(texture:Dynamic):Dynamic {
        var width:Int = texture.image.height;
        var height:Int = texture.image.width;
        var canvas:js.html.CanvasElement = js.Browser.document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        var context:js.html.CanvasRenderingContext2D = canvas.getContext("2d");
        if (this.flip) {
            context.scale(1, -1);
            context.translate(0, -height);
        }
        for (i in 0...width) {
            var sy:Int = i * width;
            var dy:Int = (this.flip) ? height - i * width : i * width;
            context.drawImage(texture.image, sy, 0, width, width, 0, dy, width, width);
        }
        return context.getImageData(0, 0, width, height);
    }

    private function parse(dataArray:Array<Int>, size:Int):Dynamic {
        var data:Uint8Array = new Uint8Array(dataArray);
        var texture3D:Data3DTexture = new Data3DTexture();
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