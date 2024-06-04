import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import haxe.ui.Toolkit;
import haxe.ui.backend.TextureBase;
import haxe.ui.backend.TextureOptions;
import haxe.ui.util.FastArray;
import haxe.ui.util.FastMap;
import haxe.ui.util.FastObject;
import haxe.ui.util.FastString;
import haxe.ui.util.MathUtil;
import haxe.ui.util.Matrix3;
import haxe.ui.util.Vector2;

class Texture extends TextureBase {

	static var DEFAULT_IMAGE:Dynamic = null;
	static var DEFAULT_MAPPING:Int = 0;
	static var DEFAULT_ANISOTROPY:Int = 1;

	public var source:Source;
	public var mipmaps:Array<Bytes>;
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
	public var onUpdate:Null<()->Void>;
	public var isRenderTargetTexture:Bool;
	public var pmremVersion:Int;

	static var _textureId:Int = 0;

	public function new(image:Dynamic = DEFAULT_IMAGE, mapping:Int = DEFAULT_MAPPING, wrapS:Int = ClampToEdgeWrapping, wrapT:Int = ClampToEdgeWrapping, magFilter:Int = LinearFilter, minFilter:Int = LinearMipmapLinearFilter, format:Int = RGBAFormat, type:Int = UnsignedByteType, anisotropy:Int = DEFAULT_ANISOTROPY, colorSpace:Int = NoColorSpace) {
		super();
		this.isTexture = true;
		this.id = _textureId++;
		this.uuid = MathUtil.generateUUID();
		this.name = "";
		this.source = new Source(image);
		this.mipmaps = new Array<Bytes>();
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
		this.userData = new FastObject();
		this.version = 0;
		this.onUpdate = null;
		this.isRenderTargetTexture = false;
		this.pmremVersion = 0;
	}

	public function get image():Dynamic {
		return this.source.data;
	}

	public function set image(value:Dynamic) {
		this.source.data = value;
	}

	public function updateMatrix() {
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
		this.userData = source.userData.copy();
		this.needsUpdate = true;
		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof(meta) == "string");
		if (!isRootObject && meta.textures[this.uuid] != null) {
			return meta.textures[this.uuid];
		}
		var output = {
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
		if (this.userData.keys().length > 0) output.userData = this.userData;
		if (!isRootObject) {
			meta.textures[this.uuid] = output;
		}
		return output;
	}

	public function dispose() {
		this.dispatchEvent({type: "dispose"});
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

	public function set needsUpdate(value:Bool) {
		if (value) {
			this.version++;
			this.source.needsUpdate = true;
		}
	}

	public function set needsPMREMUpdate(value:Bool) {
		if (value) {
			this.pmremVersion++;
		}
	}

	override public function load():Bool {
		return true;
	}

	override public function loadAsync(onDone:()->Void):Bool {
		return true;
	}

	override public function getTextureOptions():TextureOptions {
		return new TextureOptions({
			wrapS: this.wrapS,
			wrapT: this.wrapT,
			magFilter: this.magFilter,
			minFilter: this.minFilter,
			anisotropy: this.anisotropy,
			generateMipmaps: this.generateMipmaps,
			flipY: this.flipY,
			unpackAlignment: this.unpackAlignment,
			format: this.format
		});
	}

	override public function getTextureData():Dynamic {
		return this.source.data;
	}
}

class Source {

	public var data:Dynamic;
	public var needsUpdate:Bool;

	public function new(data:Dynamic) {
		this.data = data;
		this.needsUpdate = false;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof(meta) == "string");
		if (!isRootObject && meta.images[this.data] != null) {
			return meta.images[this.data];
		}
		var output = {
			uuid: this.data,
			url: this.data
		};
		if (!isRootObject) {
			meta.images[this.data] = output;
		}
		return output;
	}

}