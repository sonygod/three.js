import three.constants.LinearFilter;
import three.textures.Texture;

class VideoTexture extends Texture {

    public function new(video:Dynamic, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Float) {
        super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.isVideoTexture = true;

        this.minFilter = minFilter != null ? minFilter : LinearFilter;
        this.magFilter = magFilter != null ? magFilter : LinearFilter;

        this.generateMipmaps = false;

        if (Reflect.hasField(video, "requestVideoFrameCallback")) {
            video.requestVideoFrameCallback(updateVideo);
        }
    }

    public function clone():VideoTexture {
        return new VideoTexture(this.image).copy(this);
    }

    public function update():Void {
        var video = this.image;
        var hasVideoFrameCallback = Reflect.hasField(video, "requestVideoFrameCallback");

        if (!hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA) {
            this.needsUpdate = true;
        }
    }

    private function updateVideo(_:Float):Void {
        this.needsUpdate = true;
        video.requestVideoFrameCallback(updateVideo);
    }
}