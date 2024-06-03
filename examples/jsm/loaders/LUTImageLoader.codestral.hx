import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageElement;
import js.html.HTMLImageElement;
import js.html.ImageData;
import three.Loader;
import three.TextureLoader;
import three.Data3DTexture;
import three.RGBAFormat;
import three.UnsignedByteType;
import three.ClampToEdgeWrapping;
import three.LinearFilter;

class LUTImageLoader extends Loader {
    private var flip:Bool;

    public function new(flipVertical:Bool = false) {
        super();
        this.flip = flipVertical;
    }

    public function load(url:String, onLoad:Null<(data:Dynamic) -> Void>, onProgress:Null<(request:ProgressEvent) -> Void>, onError:Null<(event:ErrorEvent) -> Void>) {
        var loader = new TextureLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);
        loader.setPath(this.path);
        loader.load(url, function(texture) {
            try {
                var imageData:ImageData;
                if (texture.image.width < texture.image.height) {
                    imageData = this.getImageData(texture);
                } else {
                    imageData = this.horz2Vert(texture);
                }
                if (onLoad != null) {
                    onLoad(this.parse(imageData.data, Math.min(texture.image.width, texture.image.height)));
                }
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function getImageData(texture):ImageData {
        var canvas = js.html.CanvasElement.create();
        canvas.width = texture.image.width;
        canvas.height = texture.image.height;
        var context = canvas.getContext("2d");
        if (this.flip) {
            context.scale(1, -1);
            context.translate(0, -canvas.height);
        }
        context.drawImage(texture.image, 0, 0);
        return context.getImageData(0, 0, canvas.width, canvas.height);
    }

    private function horz2Vert(texture):ImageData {
        var canvas = js.html.CanvasElement.create();
        canvas.width = texture.image.height;
        canvas.height = texture.image.width;
        var context = canvas.getContext("2d");
        if (this.flip) {
            context.scale(1, -1);
            context.translate(0, -canvas.height);
        }
        for (var i:Int = 0; i < canvas.width; i++) {
            var sy = i * canvas.width;
            var dy = this.flip ? canvas.height - i * canvas.width : i * canvas.width;
            context.drawImage(texture.image, sy, 0, canvas.width, canvas.width, 0, dy, canvas.width, canvas.width);
        }
        return context.getImageData(0, 0, canvas.width, canvas.height);
    }

    private function parse(dataArray:Uint8Array, size:Int):Dynamic {
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
        return {
            size: size,
            texture3D: texture3D
        };
    }
}