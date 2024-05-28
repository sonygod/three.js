package three.src.textures;

import three.extras.ImageUtils;
import three.math.MathUtils;

class Source {
    public static var _sourceId:Int = 0;

    public var id:Int;
    public var uuid:String;
    public var data:Dynamic;
    public var dataReady:Bool;
    public var version:Int;

    public function new(?data:Dynamic) {
        this.id = _sourceId++;
        this.uuid = MathUtils.generateUUID();
        this.data = data;
        this.dataReady = true;
        this.version = 0;
    }

    public function set_needsUpdate(value:Bool) {
        if (value) this.version++;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject:Bool = (meta == null || Std.isOfType(meta, String));

        if (!isRootObject && meta.images[this.uuid] != null) {
            return meta.images[this.uuid];
        }

        var output = {
            uuid: this.uuid,
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
            meta.images[this.uuid] = output;
        }

        return output;
    }

    static function serializeImage(image:Dynamic):Dynamic {
        if ((typeof HTMLImageElement != "undefined" && Std.isOfType(image, HTMLImageElement)) ||
            (typeof HTMLCanvasElement != "undefined" && Std.isOfType(image, HTMLCanvasElement)) ||
            (typeof ImageBitmap != "undefined" && Std.isOfType(image, ImageBitmap))) {
            // default images
            return ImageUtils.getDataURL(image);
        } else {
            if (image.data != null) {
                // images of DataTexture
                return {
                    data: [for (i in 0...image.data.length) image.data[i]],
                    width: image.width,
                    height: image.height,
                    type: Type.getClassName(image.data)
                };
            } else {
                trace("THREE.Texture: Unable to serialize Texture.");
                return {};
            }
        }
    }
}