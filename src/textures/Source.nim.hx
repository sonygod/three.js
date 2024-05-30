import three.extras.ImageUtils.getDataURL;
import three.math.MathUtils.generateUUID;

class Source {
    public var isSource:Bool = true;
    public var id:Int;
    public var uuid:String;
    public var data:Dynamic;
    public var dataReady:Bool = true;
    public var version:Int = 0;

    public function new(data:Dynamic = null) {
        this.id = _sourceId++;
        this.uuid = generateUUID();
        this.data = data;
        this.dataReady = true;
        this.version = 0;
    }

    public function set needsUpdate(value:Bool) {
        if (value == true) this.version++;
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
            var url;
            if (Type.getClass(data) == Array<Dynamic>) {
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
        if ((Type.getClassName(HtmlImageElement) != null && Type.instance(image, HtmlImageElement)) ||
            (Type.getClassName(HtmlCanvasElement) != null && Type.instance(image, HtmlCanvasElement)) ||
            (Type.getClassName(ImageBitmap) != null && Type.instance(image, ImageBitmap))) {
            // default images
            return getDataURL(image);
        } else {
            if (image.data != null) {
                // images of DataTexture
                return {
                    data: Array.from(image.data),
                    width: image.width,
                    height: image.height,
                    type: Type.getClassName(image.data)
                };
            } else {
                trace('THREE.Texture: Unable to serialize Texture.');
                return {};
            }
        }
    }
}