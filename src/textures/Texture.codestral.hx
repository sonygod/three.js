import js.html.EventDispatcher;
import three.constants.MirroredRepeatWrapping;
import three.constants.ClampToEdgeWrapping;
import three.constants.RepeatWrapping;
import three.constants.UnsignedByteType;
import three.constants.RGBAFormat;
import three.constants.LinearMipmapLinearFilter;
import three.constants.LinearFilter;
import three.constants.UVMapping;
import three.constants.NoColorSpace;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Matrix3;
import three.textures.Source;

class Texture extends EventDispatcher {

    private static var _textureId: Int = 0;

    public var isTexture: Bool = true;
    public var id: Int;
    public var uuid: String;
    public var name: String = "";
    public var source: Source;
    public var mipmaps: Array<dynamic>;
    public var mapping: Int;
    public var channel: Int = 0;
    public var wrapS: Int;
    public var wrapT: Int;
    public var magFilter: Int;
    public var minFilter: Int;
    public var anisotropy: Int;
    public var format: Int;
    public var internalFormat: Null<Int>;
    public var type: Int;
    public var offset: Vector2;
    public var repeat: Vector2;
    public var center: Vector2;
    public var rotation: Float = 0;
    public var matrixAutoUpdate: Bool = true;
    public var matrix: Matrix3;
    public var generateMipmaps: Bool = true;
    public var premultiplyAlpha: Bool = false;
    public var flipY: Bool = true;
    public var unpackAlignment: Int = 4;
    public var colorSpace: Int;
    public var userData: Dynamic = {};
    public var version: Int = 0;
    public var onUpdate: Null<Function>;
    public var isRenderTargetTexture: Bool = false;
    public var pmremVersion: Int = 0;

    public function new(image: dynamic = Texture.DEFAULT_IMAGE, mapping: Int = Texture.DEFAULT_MAPPING, wrapS: Int = ClampToEdgeWrapping, wrapT: Int = ClampToEdgeWrapping, magFilter: Int = LinearFilter, minFilter: Int = LinearMipmapLinearFilter, format: Int = RGBAFormat, type: Int = UnsignedByteType, anisotropy: Int = Texture.DEFAULT_ANISOTROPY, colorSpace: Int = NoColorSpace) {

        super();

        this.id = _textureId++;
        this.uuid = MathUtils.generateUUID();
        this.source = new Source(image);
        this.mipmaps = [];
        this.mapping = mapping;
        this.wrapS = wrapS;
        this.wrapT = wrapT;
        this.magFilter = magFilter;
        this.minFilter = minFilter;
        this.anisotropy = anisotropy;
        this.format = format;
        this.internalFormat = null;
        this.type = type;
        this.offset = new Vector2(0, 0);
        this.repeat = new Vector2(1, 1);
        this.center = new Vector2(0, 0);
        this.matrix = new Matrix3();
        this.colorSpace = colorSpace;
    }

    @:get(image)
    public function get_image(): dynamic {
        return this.source.data;
    }

    @:set(image)
    public function set_image(value: dynamic = null): Void {
        this.source.data = value;
    }

    public function updateMatrix(): Void {
        this.matrix.setUvTransform(this.offset.x, this.offset.y, this.repeat.x, this.repeat.y, this.rotation, this.center.x, this.center.y);
    }

    public function clone(): Texture {
        return new Texture().copy(this);
    }

    public function copy(source: Texture): Texture {
        this.name = source.name;
        this.source = source.source;
        this.mipmaps = source.mipmaps.slice();
        this.mapping = source.mapping;
        this.channel = source.channel;
        this.wrapS = source.wrapS;
        this.wrapT = source.wrapT;
        this.magFilter = source.magFilter;
        this.minFilter = source.minFilter;
        this.anisotropy = source.anisotropy;
        this.format = source.format;
        this.internalFormat = source.internalFormat;
        this.type = source.type;
        this.offset.copy(source.offset);
        this.repeat.copy(source.repeat);
        this.center.copy(source.center);
        this.rotation = source.rotation;
        this.matrixAutoUpdate = source.matrixAutoUpdate;
        this.matrix.copy(source.matrix);
        this.generateMipmaps = source.generateMipmaps;
        this.premultiplyAlpha = source.premultiplyAlpha;
        this.flipY = source.flipY;
        this.unpackAlignment = source.unpackAlignment;
        this.colorSpace = source.colorSpace;
        this.userData = JSON.parse(JSON.stringify(source.userData));
        this.needsUpdate = true;
        return this;
    }

    public function toJSON(meta: dynamic): Dynamic {
        var isRootObject: Bool = (meta == null || Type.getClass(meta) == String);
        if (!isRootObject && meta.textures[this.uuid] != null) return meta.textures[this.uuid];

        var output: Dynamic = {
            metadata: {
                version: 4.6,
                type: "Texture",
                generator: "Texture.toJSON"
            },
            uuid: this.uuid,
            name: this.name,
            image: this.source.toJSON(meta).uuid,
            mapping: this.mapping,
            channel: this.channel,
            repeat: [this.repeat.x, this.repeat.y],
            offset: [this.offset.x, this.offset.y],
            center: [this.center.x, this.center.y],
            rotation: this.rotation,
            wrap: [this.wrapS, this.wrapT],
            format: this.format,
            internalFormat: this.internalFormat,
            type: this.type,
            colorSpace: this.colorSpace,
            minFilter: this.minFilter,
            magFilter: this.magFilter,
            anisotropy: this.anisotropy,
            flipY: this.flipY,
            generateMipmaps: this.generateMipmaps,
            premultiplyAlpha: this.premultiplyAlpha,
            unpackAlignment: this.unpackAlignment
        };

        if (Reflect.fields(this.userData).length > 0) output.userData = this.userData;
        if (!isRootObject) meta.textures[this.uuid] = output;
        return output;
    }

    public function dispose(): Void {
        this.dispatchEvent({type: "dispose"});
    }

    public function transformUv(uv: Vector2): Vector2 {
        if (this.mapping != UVMapping) return uv;

        uv.applyMatrix3(this.matrix);

        if (uv.x < 0 || uv.x > 1) {
            switch (this.wrapS) {
                case RepeatWrapping:
                    uv.x = uv.x - Math.floor(uv.x);
                    break;
                case ClampToEdgeWrapping:
                    uv.x = uv.x < 0 ? 0 : 1;
                    break;
                case MirroredRepeatWrapping:
                    if (Math.abs(Math.floor(uv.x) % 2) == 1) {
                        uv.x = Math.ceil(uv.x) - uv.x;
                    } else {
                        uv.x = uv.x - Math.floor(uv.x);
                    }
                    break;
            }
        }

        if (uv.y < 0 || uv.y > 1) {
            switch (this.wrapT) {
                case RepeatWrapping:
                    uv.y = uv.y - Math.floor(uv.y);
                    break;
                case ClampToEdgeWrapping:
                    uv.y = uv.y < 0 ? 0 : 1;
                    break;
                case MirroredRepeatWrapping:
                    if (Math.abs(Math.floor(uv.y) % 2) == 1) {
                        uv.y = Math.ceil(uv.y) - uv.y;
                    } else {
                        uv.y = uv.y - Math.floor(uv.y);
                    }
                    break;
            }
        }

        if (this.flipY) uv.y = 1 - uv.y;

        return uv;
    }

    @:set(needsUpdate)
    public function set_needsUpdate(value: Bool): Void {
        if (value) {
            this.version++;
            this.source.needsUpdate = true;
        }
    }

    @:set(needsPMREMUpdate)
    public function set_needsPMREMUpdate(value: Bool): Void {
        if (value) this.pmremVersion++;
    }
}

class Texture {
    public static var DEFAULT_IMAGE: dynamic = null;
    public static var DEFAULT_MAPPING: Int = UVMapping;
    public static var DEFAULT_ANISOTROPY: Int = 1;
}