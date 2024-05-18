package three.textures;

import js.html.HTMLImageElement;
import js.html.HTMLCanvasElement;
import js.ImageBitmap;

class Source {

    public static var _sourceId:Int = 0;

    public var isSource:Bool;
    public var id:Int;
    public var uuid:String;
    public var data:Dynamic;
    public var dataReady:Bool;
    public var version:Int;

    public function new(?data:Dynamic) {
        isSource = true;
        id = _sourceId++;
        uuid = MathUtils.generateUUID();
        this.data = data;
        dataReady = true;
        version = 0;
    }

    public function set_needsUpdate(value:Bool) {
        if (value) version++;
    }

    public function toJSON(?meta:Any):Dynamic {
        var isRootObject:Bool = (meta == null || Std.isOfType(meta, String));
        if (!isRootObject && meta.images[uuid] != null) {
            return meta.images[uuid];
        }
        var output:Dynamic = {
            uuid: uuid,
            url: ''
        };
        var data:Dynamic = this.data;
        if (data != null) {
            var url:Dynamic;
            if (Std.isOfType(data, Array)) {
                // cube texture
                url = [];
                for (i in 0...data.length) {
                    if (data[i].isDataTexture) {
                        url.push(serializeImage(data[i].image));
                    } else {
                        url.push(serializeImage(data[i]));
                    }
                }
            } else {
                // texture
                url = serializeImage(data);
            }
            output.url = url;
        }
        if (!isRootObject) {
            meta.images[uuid] = output;
        }
        return output;
    }

    static function serializeImage(image:Dynamic):Dynamic {
        if ((typeof HTMLImageElement != 'undefined' && Std.isOfType(image, HTMLImageElement)) ||
            (typeof HTMLCanvasElement != 'undefined' && Std.isOfType(image, HTMLCanvasElement)) ||
            (typeof ImageBitmap != 'undefined' && Std.isOfType(image, ImageBitmap))) {
            // default images
            return ImageUtils.getDataURL(image);
        } else {
            if (image.data != null) {
                // images of DataTexture
                return {
                    data: [for (i in image.data) i],
                    width: image.width,
                    height: image.height,
                    type: Type.getClassName(Type.getClass(image.data))
                };
            } else {
                trace("THREE.Texture: Unable to serialize Texture.");
                return {};
            }
        }
    }
}