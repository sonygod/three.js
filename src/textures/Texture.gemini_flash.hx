import three.core.EventDispatcher;
import three.constants.Wrapping;
import three.constants.TextureConstants;
import three.constants.PixelFormat;
import three.constants.TextureDataType;
import three.constants.Mapping;
import three.constants.ColorSpace;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Matrix3;
import three.textures.Source;

class Texture extends EventDispatcher {
	public static var DEFAULT_IMAGE:Null<Image> = null;
	public static var DEFAULT_MAPPING:Int = Mapping.UVMapping;
	public static var DEFAULT_ANISOTROPY:Int = 1;
	
	static var _textureId:Int = 0;

	public var isTexture(default, never):Bool = true;
	public var id(default, null):Int;
	public var uuid(default, null):String;
	public var name:String;
	public var source:Source;
	public var mipmaps:Array<Dynamic>;
	public var mapping:Int;
	public var channel:Int;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var anisotropy:Int;
	public var format:Int;
	public var internalFormat:Null<Int>;
	public var type:Int;
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
	public var colorSpace:Int;
	public var userData:Dynamic;
	public var version:Int;
	public var onUpdate:Null<Void->Void>;
	public var isRenderTargetTexture:Bool;
	public var pmremVersion:Int;

	public function new(image:Dynamic = Texture.DEFAULT_IMAGE, mapping:Int = Texture.DEFAULT_MAPPING, wrapS:Int = Wrapping.ClampToEdgeWrapping, wrapT:Int = Wrapping.ClampToEdgeWrapping, magFilter:Int = TextureConstants.LinearFilter, minFilter:Int = TextureConstants.LinearMipmapLinearFilter, format:Int = PixelFormat.RGBAFormat, type:Int = TextureDataType.UnsignedByteType, anisotropy:Int = Texture.DEFAULT_ANISOTROPY, colorSpace:Int = ColorSpace.NoColorSpace) {
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

	public function set_image(value:Dynamic = null):Dynamic {
		return this.source.data = value;
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
		this.mipmaps = source.mipmaps.slice(0);

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

		this.userData = {};
		for (k in Reflect.fields(source.userData)) {
			Reflect.setField(this.userData, k, Reflect.field(source.userData, k));
		}

		this.needsUpdate = true;

		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject:Bool = (meta == null || Std.isOfType(meta, String));

		if (!isRootObject && Reflect.hasField(meta.textures, this.uuid)) {
			return Reflect.field(meta.textures, this.uuid);
		}

		var output = {
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

		var userDataFields = Reflect.fields(this.userData);
		if (userDataFields.length > 0) {
			output.userData = {};
			for (k in userDataFields) {
				Reflect.setField(output.userData, k, Reflect.field(this.userData, k));
			}
		}
		
		if (!isRootObject) {
			Reflect.setField(meta.textures, this.uuid, output);
		}

		return output;
	}

	public function dispose():Void {
		dispatchEvent({ type : 'dispose' });
	}

	public function transformUv(uv:Vector2):Vector2 {
		if (this.mapping != Mapping.UVMapping) {
			return uv;
		}

		uv.applyMatrix3(this.matrix);

		if (uv.x < 0 || uv.x > 1) {
			switch (this.wrapS) {
				case Wrapping.RepeatWrapping:
					uv.x = uv.x - Math.floor(uv.x);
				case Wrapping.ClampToEdgeWrapping:
					uv.x = uv.x < 0 ? 0 : 1;
				case Wrapping.MirroredRepeatWrapping:
					if (Math.abs(Math.floor(uv.x) % 2) == 1) {
						uv.x = Math.ceil(uv.x) - uv.x;
					} else {
						uv.x = uv.x - Math.floor(uv.x);
					}
			}
		}

		if (uv.y < 0 || uv.y > 1) {
			switch (this.wrapT) {
				case Wrapping.RepeatWrapping:
					uv.y = uv.y - Math.floor(uv.y);
				case Wrapping.ClampToEdgeWrapping:
					uv.y = uv.y < 0 ? 0 : 1;
				case Wrapping.MirroredRepeatWrapping:
					if (Math.abs(Math.floor(uv.y) % 2) == 1) {
						uv.y = Math.ceil(uv.y) - uv.y;
					} else {
						uv.y = uv.y - Math.floor(uv.y);
					}
			}
		}

		if (this.flipY) {
			uv.y = 1 - uv.y;
		}

		return uv;
	}

	public function set_needsUpdate(value:Bool):Bool {
		if (value) {
			this.version++;
			this.source.needsUpdate = true;
		}
		return value;
	}

	public function set_needsPMREMUpdate(value:Bool):Bool {
		if (value) {
			this.pmremVersion++;
		}
		return value;
	}
}