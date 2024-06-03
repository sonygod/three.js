import three.extras.ImageUtils;
import three.math.MathUtils;

class Source {
    public var isSource:Bool = true;
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

    public function set_needsUpdate(value:Bool):Void {
        if (value) this.version++;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject = meta === null || meta is String;

        if (!isRootObject && meta.images[this.uuid] !== null) {
            return meta.images[this.uuid];
        }

        var output = {
            uuid: this.uuid,
            url: ''
        };

        if (this.data !== null) {
            var url:Dynamic;

            if (Std.is(this.data, Array)) {
                url = [];
                for (data in this.data) {
                    if (Std.is(data, three.textures.DataTexture)) {
                        url.push(serializeImage(data.image));
                    } else {
                        url.push(serializeImage(data));
                    }
                }
            } else {
                url = serializeImage(this.data);
            }

            output.url = url;
        }

        if (!isRootObject) {
            meta.images[this.uuid] = output;
        }

        return output;
    }
}

function serializeImage(image:Dynamic):Dynamic {
    if (Std.is(image, js.html.HTMLImageElement) || Std.is(image, js.html.HTMLCanvasElement) || Std.is(image, js.html.ImageBitmap)) {
        return ImageUtils.getDataURL(image);
    } else if (image.data !== null) {
        return {
            data: Array<Int>(image.data),
            width: image.width,
            height: image.height,
            type: Type.getClassName(Type.getClass(image.data))
        };
    } else {
        trace('THREE.Texture: Unable to serialize Texture.');
        return {};
    }
}

var _sourceId:Int = 0;