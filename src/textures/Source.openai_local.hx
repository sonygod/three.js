import three.extras.ImageUtils;
import three.math.MathUtils;

class Source {

    public var isSource:Bool;
    @:isVar public var id(default, null):Int;
    public var uuid:String;
    public var data:Dynamic;
    public var dataReady:Bool;
    public var version:Int;

    private static var _sourceId:Int = 0;

    public function new(data:Dynamic = null) {
        this.isSource = true;
        this.id = _sourceId++;
        this.uuid = MathUtils.generateUUID();
        this.data = data;
        this.dataReady = true;
        this.version = 0;
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value == true) this.version++;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var isRootObject:Bool = (meta == null || Std.is(meta, String));

        if (!isRootObject && meta.images.exists(this.uuid)) {
            return meta.images.get(this.uuid);
        }

        var output:Dynamic = {
            uuid: this.uuid,
            url: ''
        };

        var data = this.data;

        if (data != null) {
            var url:Dynamic;

            if (Type.typeof(data) == Type.TClass(Array)) {
                // cube texture
                url = [];

                for (i in 0...data.length) {
                    if (Reflect.hasField(data[i], "isDataTexture") && Reflect.field(data[i], "isDataTexture")) {
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
            meta.images.set(this.uuid, output);
        }

        return output;
    }

    static function serializeImage(image:Dynamic):Dynamic {
        if ((Type.getClassName(Type.getClass(image)) == "HTMLImageElement") ||
            (Type.getClassName(Type.getClass(image)) == "HTMLCanvasElement") ||
            (Type.getClassName(Type.getClass(image)) == "ImageBitmap")) {
            // default images
            return ImageUtils.getDataURL(image);
        } else {
            if (Reflect.hasField(image, "data") && image.data != null) {
                // images of DataTexture
                return {
                    data: Array.from(image.data),
                    width: image.width,
                    height: image.height,
                    type: Type.getClassName(Type.getClass(image.data))
                };
            } else {
                trace('THREE.Texture: Unable to serialize Texture.');
                return {};
            }
        }
    }

}