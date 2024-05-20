import three.extras.ImageUtils;
import three.math.MathUtils;

class Source {

    static var _sourceId = 0;

    public var id:Int;
    public var uuid:String;
    public var data:Dynamic;
    public var dataReady:Bool = true;
    public var version:Int = 0;

    public function new(data:Dynamic = null) {
        this.id = _sourceId++;
        this.uuid = MathUtils.generateUUID();
        this.data = data;
    }

    public function set needsUpdate(value:Bool) {
        if (value) this.version++;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject = (meta == null || Std.is(meta, String));
        if (!isRootObject && meta.images[this.uuid] != null) {
            return meta.images[this.uuid];
        }
        var output = {
            uuid: this.uuid,
            url: ''
        };
        var data = this.data;
        if (data != null) {
            var url:Dynamic;
            if (Std.is(data, Array)) {
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
        if ((Std.is(HTMLImageElement, image) || Std.is(HTMLCanvasElement, image) || Std.is(ImageBitmap, image))) {
            // default images
            return ImageUtils.getDataURL(image);
        } else {
            if (image.data != null) {
                // images of DataTexture
                return {
                    data: Array.from(image.data),
                    width: image.width,
                    height: image.height,
                    type: image.data.constructor.name
                };
            } else {
                trace('THREE.Texture: Unable to serialize Texture.');
                return {};
            }
        }
    }
}