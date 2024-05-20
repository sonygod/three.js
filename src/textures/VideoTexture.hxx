import three.js.src.constants.LinearFilter;
import three.js.src.textures.Texture;

class VideoTexture extends Texture {

	public function new(video:Video, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic) {
		super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

		this.isVideoTexture = true;

		this.minFilter = minFilter != null ? minFilter : LinearFilter;
		this.magFilter = magFilter != null ? magFilter : LinearFilter;

		this.generateMipmaps = false;

		var scope = this;

		function updateVideo() {
			scope.needsUpdate = true;
			video.requestVideoFrameCallback(updateVideo);
		}

		if (Std.hasField(video, "requestVideoFrameCallback")) {
			video.requestVideoFrameCallback(updateVideo);
		}
	}

	public function clone():VideoTexture {
		return new VideoTexture(this.image).copy(this);
	}

	public function update():Void {
		var video = this.image;
		var hasVideoFrameCallback = Std.hasField(video, "requestVideoFrameCallback");

		if (hasVideoFrameCallback == false && video.readyState >= video.HAVE_CURRENT_DATA) {
			this.needsUpdate = true;
		}
	}
}