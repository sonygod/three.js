import haxe.Serializer;
import haxe.Unserializer;
import js.Browser;
import js.html.ImageData;
import js.html.ImageElement;
import openfl._internal.Lib;
import openfl.display.BitmapData;
import openfl.display.IBitmapDrawable;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.EventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Texture extends EventDispatcher {
	public var id:Int;
	public var isRenderTargetTexture:Bool;
	public var isTexture:Bool;
	public var pmremVersion:Int;
	public var uuid:String;
	public var name:String;
	public var source:Source;
	public var mipmaps:Array<BitmapData>;
	public var mapping:String;
	public var channel:Int;
	public var wrapS:String;
	public var wrapT:String;
	public var magFilter:String;
	public var minFilter:String;
	public var anisotropy:Int;
	public var format:String;
	public var internalFormat:String;
	public var type:String;
	public var offset:Vector2;
	public var repeat:Vector2;
	public var center:Vector2;
	public var rotation:Float;
	public var matrixAutoUpdate:Bool;
	public var matrix:Matrix3D;
	public var generateMipmaps:Bool;
	public var premultiplyAlpha:Bool;
	public var flipY:Bool;
	public var unpackAlignment:Int;
	public var colorSpace:String;
	public var userData:Dynamic;
	public var version:Int;
	public var onUpdate:Void->Void;

	public static var DEFAULT_IMAGE:ImageElement;
	public static var DEFAULT_MAPPING:String;
	public static var DEFAULT_ANISOTROPY:Int;

	public function new(image:ImageElement = null, mapping:String = null, wrapS:String = null, wrapT:String = null, magFilter:String = null, minFilter:String = null, format:String = null, type:String = null, anisotropy:Int = null, colorSpace:String = null) {
		super();
		isTexture = true;
		id = _textureId++;
		uuid = Lib.generateUUID();
		name = "";
		source = new Source(image);
		mipmaps = [];
		this.mapping = mapping != null ? mapping : DEFAULT_MAPPING;
		channel = 0;
		this.wrapS = wrapS != null ? wrapS : ClampToEdgeWrapping;
		this.wrapT = wrapT != null ? wrapT : ClampToEdgeWrapping;
		this.magFilter = magFilter != null ? magFilter : LinearFilter;
		this.minFilter = minFilter != null ? minFilter : LinearMipmapLinearFilter;
		anisotropy = anisotropy != null ? anisotropy : DEFAULT_ANISOTROPY;
		format = format != null ? format : RGBAFormat;
		internalFormat = null;
		this.type = type != null ? type : UnsignedByteType;
		offset = new Vector2(0, 0);
		repeat = new Vector2(1, 1);
		center = new Vector2(0, 0);
		rotation = 0;
		matrixAutoUpdate = true;
		matrix = new Matrix3D();
		generateMipmaps = true;
		premultiplyAlpha = false;
		flipY = true;
		unpackAlignment = 4;
		colorSpace = colorSpace != null ? colorSpace : NoColorSpace;
		userData = {};
		version = 0;
		isRenderTargetTexture = false;
		pmremVersion = 0;
	}

	public function get_image():ImageElement {
		return source.data;
	}

	public function set_image(value:ImageElement) {
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
		this.source = source.source;
		mipmaps = source.mipmaps.slice();
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
		offset.copyFrom(source.offset);
		repeat.copyFrom(source.repeat);
		center.copyFrom(source.center);
		rotation = source.rotation;
		matrixAutoUpdate = source.matrixAutoUpdate;
		matrix.copyFrom(source.matrix);
		generateMipmaps = source.generateMipmaps;
		premultiplyAlpha = source.premultiplyAlpha;
		flipY = source.flipY;
		unpackAlignment = source.unpackAlignment;
		colorSpace = source.colorSpace;
		userData = unserialize(serialize(source.userData));
		needsUpdate = true;
		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject:Bool = (meta == null || typeof meta == "string");
		if (!isRootObject && meta.textures != null && meta.textures.exists(uuid)) {
			return meta.textures.get(uuid);
		}
		var output:Dynamic = {
			metadata: {
				version: 4.6,
				type: "Texture",
				generator: "Texture.toJSON"
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
		if (userData.keys.length > 0) output.userData = userData;
		if (!isRootObject) {
			meta.textures[uuid] = output;
		}
		return output;
	}

	public function dispose():Void {
		dispatchEvent(new openfl.events.Event(openfl.events.Event.DISPOSE));
	}

	public function transformUv(uv:Vector2):Vector2 {
		if (mapping != UVMapping) return uv;
		uv.applyMatrix3(matrix);
		if (uv.x < 0 || uv.x > 1) {
			switch (wrapS) {
				case RepeatWrapping:
					uv.x = uv.x % 1;
					break;
				case ClampToEdgeWrapping:
					uv.x = uv.x < 0 ? 0 : 1;
					break;
				case MirroredRepeatWrapping:
					if (Math.abs(Math.floor(uv.x) % 2) == 1) {
						uv.x = Math.ceil(uv.x) - uv.x;
					} else {
						uv.x = uv.x % 1;
					}
					break;
			}
		}
		if (uv.y < 0 || uv.y > 1) {
			switch (wrapT) {
				case RepeatWrapping:
					uv.y = uv.y % 1;
					break;
				case ClampToEdgeWrapping:
					uv.y = uv.y < 0 ? 0 : 1;
					break;
				case MirroredRepeatWrapping:
					if (Math.abs(Math.floor(uv.y) % 2) == 1) {
						uv.y = Math.ceil(uv.y) - uv.y;
					} else {
						uv.y = uv.y % 1;
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

	public static function fromBitmapData(bitmapData:BitmapData, ?repeat:Bool, ?smooth:Bool):Texture {
		var sourceBitmapData:BitmapData = bitmapData;
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		sourceBitmapData.source = source;
		texture.source = source;
		texture.mipmaps = [sourceBitmapData];
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = sourceBitmapData.premultiplied;
		texture.flipY = !sourceBitmapData.height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromBitmapDataArray(bitmapDatas:Array<BitmapData>, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.mipmaps = bitmapDatas;
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = bitmapDatas[0].premultiplied;
		texture.flipY = !bitmapDatas[0].height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromFile(url:String, ?crossOrigin:String, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.generateMipmaps = true;
		if (crossOrigin != null) {
			source.crossOrigin = crossOrigin;
		}
		source.load(url, function() {
			texture.mipmaps = [source.bitmapData];
			texture.premultiplyAlpha = source.bitmapData.premultiplied;
			texture.flipY = !source.bitmapData.height;
			if (repeat != null) {
				texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
				texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			}
			if (smooth != null) {
				texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
				texture.magFilter = smooth ? LinearFilter : NearestFilter;
			}
		});
		return texture;
	}

	public static function fromImage(image:ImageElement, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(image);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.mipmaps = [source.bitmapData];
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = source.bitmapData.premultiplied;
		texture.flipY = !source.bitmapData.height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromCanvas(canvas:HTMLCanvasElement, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.mipmaps = [BitmapData.fromCanvas(canvas)];
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = texture.mipmaps[0].premultiplied;
		texture.flipY = !texture.mipmaps[0].height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromData(width:Int, height:Int, data:ByteArray, ?format:String, ?type:String, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.mipmaps = [BitmapData.fromData(width, height, format != null ? format : RGBAFormat, type != null ? type : UnsignedByteType, data)];
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = texture.mipmaps[0].premultiplied;
		texture.flipY = !texture.mipmaps[0].height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromRenderTexture(renderTexture:RenderTexture, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var texture:Texture = new Texture(null, null, null, null, null, null, null, null, null, null);
		texture.source = source;
		texture.mipmaps = [renderTexture.getBitmapData()];
		texture.generateMipmaps = false;
		texture.premultiplyAlpha = texture.mipmaps[0].premultiplied;
		texture.flipY = !texture.mipmaps[0].height;
		if (repeat != null) {
			texture.wrapS = repeat ? RepeatWrapping : ClampToEdgeWrapping;
			texture.wrapT = repeat ? RepeatWrapping : ClampToEdgeWrapping;
		}
		if (smooth != null) {
			texture.minFilter = smooth ? LinearMipmapLinearFilter : NearestFilter;
			texture.magFilter = smooth ? LinearFilter : NearestFilter;
		}
		return texture;
	}

	public static function fromTexture(texture:Texture, ?repeat:Bool, ?smooth:Bool):Texture {
		var source:Source = new Source(null);
		var newTexture:Texture = new Texture(null,