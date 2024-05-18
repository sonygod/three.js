package three.textures;

import three.core.EventDispatcher;
import three.constants.*;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Matrix3;
import three.textures.Source;

class Texture extends EventDispatcher {

    static public var DEFAULT_IMAGE:Dynamic = null;
    static public var DEFAULT_MAPPING:UVMapping = UVMapping;
    static public var DEFAULT_ANISOTROPY:Int = 1;

    private static var _textureId:Int = 0;

    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var source:Source;
    public var mipmaps:Array<Dynamic>;
    public var mapping:UVMapping;
    public var channel:Int;
    public var wrapS:WrappingMode;
    public var wrapT:WrappingMode;
    public var magFilter:TextureFilter;
    public var minFilter:TextureFilter;
    public var anisotropy:Int;
    public var format:TextureFormat;
    public var internalFormat:TextureFormat;
    public var type:TextureType;
    public var offset:Vector2;
    public var repeat:Vector2;
    public var center:Vector2;
    public var rotation:Float;
    public var matrixAutoUpdate:Bool;
    public var matrix:Matrix3;
    public var generateMipmaps:Bool;
    public var premultiplyAlpha:Bool;
    public var flipY:Bool;
    public var unpackAlignment:Int;
    public var colorSpace:ColorSpace;
    public var userData:Dynamic;
    public var version:Int;
    public var onUpdate:Void -> Void;
    public var isRenderTargetTexture:Bool;
    public var pmremVersion:Int;

    public function new(image:Dynamic = null, mapping:UVMapping = UVMapping, wrapS:WrappingMode = ClampToEdgeWrapping, wrapT:WrappingMode = ClampToEdgeWrapping, magFilter:TextureFilter = LinearFilter, minFilter:TextureFilter = LinearMipmapLinearFilter, format:TextureFormat = RGBAFormat, type:TextureType = UnsignedByteType, anisotropy:Int = 1, colorSpace:ColorSpace = NoColorSpace) {
        super();

        this.id = _textureId++;
        this.uuid = MathUtils.generateUUID();

        this.name = '';

        this.source = new Source(image);
        this.mipmaps = [];

        this.mapping = mapping;
        this.channel = 0;

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
        this.rotation = 0;

        this.matrixAutoUpdate = true;
        this.matrix = new Matrix3();

        this.generateMipmaps = true;
        this.premultiplyAlpha = false;
        this.flipY = true;
        this.unpackAlignment = 4; // valid values: 1, 2, 4, 8 (see http://www.khronos.org/opengles/sdk/docs/man/xhtml/glPixelStorei.xml)

        this.colorSpace = colorSpace;

        this.userData = {};

        this.version = 0;
        this.onUpdate = null;

        this.isRenderTargetTexture = false; // indicates whether a texture belongs to a render target or not
        this.pmremVersion = 0; // indicates whether this texture should be processed by PMREMGenerator or not (only relevant for render target textures)
    }

    public function get_image():Dynamic {
        return this.source.data;
    }

    public function set_image(value:Dynamic = null):Void {
        this.source.data = value;
    }

    public function updateMatrix():Void {
        this.matrix.setUvTransform(this.offset.x, this.offset.y, this.repeat.x, this.repeat.y, this.rotation, this.center.x, this.center.y);
    }

    public function clone():Texture {
        return new Texture().copy(this);
    }

    public function copy(source:Texture):Texture {
        this.name = source.name;

        this.source = source.source;
        this.mipmaps = source.mipmaps.copy();

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

        this.offset.copyFrom(source.offset);
        this.repeat.copyFrom(source.repeat);
        this.center.copyFrom(source.center);
        this.rotation = source.rotation;

        this.matrixAutoUpdate = source.matrixAutoUpdate;
        this.matrix.copyFrom(source.matrix);

        this.generateMipmaps = source.generateMipmaps;
        this.premultiplyAlpha = source.premultiplyAlpha;
        this.flipY = source.flipY;
        this.unpackAlignment = source.unpackAlignment;
        this.colorSpace = source.colorSpace;

        this.userData = Json.parse(Json.stringify(source.userData));

        this.needsUpdate = true;

        return this;
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var isRootObject:Bool = (meta == null || Std.is(meta, String));

        if (!isRootObject && meta.textures[this.uuid] != null) {
            return meta.textures[this.uuid];
        }

        var output:Dynamic = {
            metadata: {
                version: 4.6,
                type: 'Texture',
                generator: 'Texture.toJSON'
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

        if (Lambda.count(this.userData) > 0) output.userData = this.userData;

        if (!isRootObject) {
            meta.textures[this.uuid] = output;
        }

        return output;
    }

    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }

    public function transformUv(uv:Vector2):Vector2 {
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

        if (this.flipY) {
            uv.y = 1 - uv.y;
        }

        return uv;
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value == true) {
            this.version++;
            this.source.needsUpdate = true;
        }
    }

    public function set_needsPMREMUpdate(value:Bool):Void {
        if (value == true) {
            this.pmremVersion++;
        }
    }
}