package three.textures;

import three.core.EventDispatcher;
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
    public static var DEFAULT_IMAGE:Dynamic = null;
    public static var DEFAULT_MAPPING:UVMapping = UVMapping;
    public static var DEFAULT_ANISOTROPY:Float = 1.0;

    private static var _textureId:Int = 0;

    public var id:Int;
    public var uuid:String;
    public var name:String;
    public var source:Source;
    public var mipmaps:Array<Dynamic>;
    public var mapping:UVMapping;
    public var channel:Int;
    public var wrapS:WrapMode;
    public var wrapT:WrapMode;
    public var magFilter:Filter;
    public var minFilter:Filter;
    public var anisotropy:Float;
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
    public var onUpdate:Void->Void;
    public var isRenderTargetTexture:Bool;
    public var pmremVersion:Int;

    public function new(image:Dynamic = null, mapping:UVMapping = UVMapping, wrapS:WrapMode = ClampToEdgeWrapping, wrapT:WrapMode = ClampToEdgeWrapping, magFilter:Filter = LinearFilter, minFilter:Filter = LinearMipmapLinearFilter, format:TextureFormat = RGBAFormat, type:TextureType = UnsignedByteType, anisotropy:Float = Texture.DEFAULT_ANISOTROPY, colorSpace:ColorSpace = NoColorSpace) {
        super();

        this.isTexture = true;

        id = _textureId++;
        uuid = MathUtils.generateUUID();

        name = '';
        source = new Source(image);
        mipmaps = [];

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

        offset = new Vector2(0, 0);
        repeat = new Vector2(1, 1);
        center = new Vector2(0, 0);
        rotation = 0;

        matrixAutoUpdate = true;
        matrix = new Matrix3();

        generateMipmaps = true;
        premultiplyAlpha = false;
        flipY = true;
        unpackAlignment = 4; // valid values: 1, 2, 4, 8 (see http://www.khronos.org/opengles/sdk/docs/man/xhtml/glPixelStorei.xml)

        colorSpace = colorSpace;

        userData = {};

        version = 0;
        onUpdate = null;

        isRenderTargetTexture = false; // indicates whether a texture belongs to a render target or not
        pmremVersion = 0; // indicates whether this texture should be processed by PMREMGenerator or not (only relevant for render target textures)
    }

    public function get_image():Dynamic {
        return source.data;
    }

    public function set_image(value:Dynamic = null):Void {
        source.data = value;
    }

    public function updateMatrix():Void {
        matrix.setUvTransform(offset.x, offset.y, repeat.x, repeat.y, rotation, center.x, center.y);
    }

    public function clone():Texture {
        return new Texture().copy(this);
    }

    public function copy(source:Texture):Texture {
        name = source.name;

        source = source.source;
        mipmaps = source.mipmaps.slice(0);

        mapping = source.mapping;
        channel = source.channel;

        wrapS = source.wrapS;
        wrapT = source.wrapT;

        magFilter = source.magFilter;
        minFilter = source.minFilter;

        anisotropy = source.anisotropy;

        format = source.format;
        internalFormat = source.internalFormat;
        type = source.type;

        offset.copy(source.offset);
        repeat.copy(source.repeat);
        center.copy(source.center);
        rotation = source.rotation;

        matrixAutoUpdate = source.matrixAutoUpdate;
        matrix.copy(source.matrix);

        generateMipmaps = source.generateMipmaps;
        premultiplyAlpha = source.premultiplyAlpha;
        flipY = source.flipY;
        unpackAlignment = source.unpackAlignment;
        colorSpace = source.colorSpace;

        userData = Json.parse(Json.stringify(source.userData));

        needsUpdate = true;

        return this;
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var isRootObject:Bool = (meta == null || Std.is(meta, String));

        if (!isRootObject && meta.textures != null && meta.textures[uuid] != null) {
            return meta.textures[uuid];
        }

        var output:Dynamic = {
            metadata: {
                version: '4.6',
                type: 'Texture',
                generator: 'Texture.toJSON'
            },
            uuid: uuid,
            name: name,

            image: source.toJSON(meta).uuid,

            mapping: mapping,
            channel: channel,

            repeat: [repeat.x, repeat.y],
            offset: [offset.x, offset.y],
            center: [center.x, center.y],
            rotation: rotation,

            wrap: [wrapS, wrapT],

            format: format,
            internalFormat: internalFormat,
            type: type,
            colorSpace: colorSpace,

            minFilter: minFilter,
            magFilter: magFilter,
            anisotropy: anisotropy,

            flipY: flipY,

            generateMipmaps: generateMipmaps,
            premultiplyAlpha: premultiplyAlpha,
            unpackAlignment: unpackAlignment
        };

        if (Reflect.fields(userData).length > 0) {
            output.userData = userData;
        }

        if (!isRootObject) {
            meta.textures[uuid] = output;
        }

        return output;
    }

    public function dispose():Void {
        dispatchEvent({ type: 'dispose' });
    }

    public function transformUv(uv:Vector2):Vector2 {
        if (mapping != UVMapping) return uv;

        uv.applyMatrix3(matrix);

        if (uv.x < 0 || uv.x > 1) {
            switch (wrapS) {
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
            switch (wrapT) {
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

        if (flipY) {
            uv.y = 1 - uv.y;
        }

        return uv;
    }

    public function set_needsUpdate(value:Bool):Void {
        if (value) {
            version++;
            source.needsUpdate = true;
        }
    }

    public function set_needsPMREMUpdate(value:Bool):Void {
        if (value) {
            pmremVersion++;
        }
    }
}