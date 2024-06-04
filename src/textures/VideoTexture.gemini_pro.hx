import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.filters.BitmapFilter;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class VideoTexture extends Texture {

	public var isVideoTexture:Bool;
	public var minFilter:Int;
	public var magFilter:Int;
	public var generateMipmaps:Bool;

	public function new(video:Dynamic, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Int) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

		this.isVideoTexture = true;

		this.minFilter = minFilter != null ? minFilter : LinearFilter;
		this.magFilter = magFilter != null ? magFilter : LinearFilter;

		this.generateMipmaps = false;

		var scope = this;

		function updateVideo(event:Event) {
			scope.needsUpdate = true;
			// Assuming 'video' has a method called 'requestVideoFrameCallback'
			video.requestVideoFrameCallback(updateVideo);
		}

		if (Reflect.hasField(video, 'requestVideoFrameCallback')) {
			video.requestVideoFrameCallback(updateVideo);
		}
	}

	public function clone():VideoTexture {
		return new VideoTexture(this.image).copy(this);
	}

	public function update() {
		var video = this.image;
		var hasVideoFrameCallback = Reflect.hasField(video, 'requestVideoFrameCallback');

		if (!hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA) {
			this.needsUpdate = true;
		}
	}

}

class Texture extends EventDispatcher {

	public var image:Dynamic;
	public var mapping:Int;
	public var wrapS:Int;
	public var wrapT:Int;
	public var magFilter:Int;
	public var minFilter:Int;
	public var format:Int;
	public var type:Int;
	public var anisotropy:Int;
	public var needsUpdate:Bool;

	public function new(image:Dynamic, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Int) {
		super();
		this.image = image;
		this.mapping = mapping;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.magFilter = magFilter;
		this.minFilter = minFilter;
		this.format = format;
		this.type = type;
		this.anisotropy = anisotropy;
		this.needsUpdate = false;
	}

	public function copy(source:Texture):Texture {
		this.image = source.image;
		this.mapping = source.mapping;
		this.wrapS = source.wrapS;
		this.wrapT = source.wrapT;
		this.magFilter = source.magFilter;
		this.minFilter = source.minFilter;
		this.format = source.format;
		this.type = source.type;
		this.anisotropy = source.anisotropy;
		this.needsUpdate = source.needsUpdate;
		return this;
	}

}

class LinearFilter {
	public static var value:Int = 9728;
}