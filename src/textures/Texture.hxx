import three.core.EventDispatcher;
import three.constants.*;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Matrix3;
import three.textures.Source;

class Texture extends EventDispatcher {

	var isTexture:Bool = true;
	var id:Int;
	var uuid:String;
	var name:String;
	var source:Source;
	var mipmaps:Array<Dynamic>;
	var mapping:Int;
	var channel:Int;
	var wrapS:Int;
	var wrapT:Int;
	var magFilter:Int;
	var minFilter:Int;
	var anisotropy:Int;
	var format:Int;
	var internalFormat:Dynamic;
	var type:Int;
	var offset:Vector2;
	var repeat:Vector2;
	var center:Vector2;
	var rotation:Float;
	var matrixAutoUpdate:Bool;
	var matrix:Matrix3;
	var generateMipmaps:Bool;
	var premultiplyAlpha:Bool;
	var flipY:Bool;
	var unpackAlignment:Int;
	var colorSpace:Int;
	var userData:Dynamic;
	var version:Int;
	var onUpdate:Dynamic;
	var isRenderTargetTexture:Bool;
	var pmremVersion:Int;

	public function new(image:Dynamic = Texture.DEFAULT_IMAGE, mapping:Int = Texture.DEFAULT_MAPPING, wrapS:Int = ClampToEdgeWrapping, wrapT:Int = ClampToEdgeWrapping, magFilter:Int = LinearFilter, minFilter:Int = LinearMipmapLinearFilter, format:Int = RGBAFormat, type:Int = UnsignedByteType, anisotropy:Int = Texture.DEFAULT_ANISOTROPY, colorSpace:Int = NoColorSpace) {
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
		this.unpackAlignment = 4;
		this.colorSpace = colorSpace;
		this.userData = {};
		this.version = 0;
		this.onUpdate = null;
		this.isRenderTargetTexture = false;
		this.pmremVersion = 0;
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
		this.userData = haxe.Json.parse(haxe.Json.stringify(source.userData));
		this.needsUpdate = true;
		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta === undefined || typeof meta === 'string');
		if (!isRootObject && meta.textures[this.uuid] !== undefined) {
			return meta.textures[this.uuid];
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
		if (Object.keys(this.userData).length > 0) output.userData = this.userData;
		if (!isRootObject) {
			meta.textures[this.uuid] = output;
		}
		return output;
	}

	public function dispose():Void {
		this.dispatchEvent({type: 'dispose'});
	}

	public function transformUv(uv:Vector2):Vector2 {
		if (this.mapping !== UVMapping) return uv;
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
					if (Math.abs(Math.floor(uv.x) % 2) === 1) {
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
					if (Math.abs(Math.floor(uv.y) % 2) === 1) {
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
		if (value === true) {
			this.version++;
			this.source.needsUpdate = true;
		}
	}

	public function set_needsPMREMUpdate(value:Bool):Void {
		if (value === true) {
			this.pmremVersion++;
		}
	}

	static var DEFAULT_IMAGE:Dynamic = null;
	static var DEFAULT_MAPPING:Int = UVMapping;
	static var DEFAULT_ANISOTROPY:Int = 1;
}