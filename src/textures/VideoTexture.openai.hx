package three.textures;

import three.constants.LinearFilter;
import three.textures.Texture;

class VideoTexture extends Texture {
    public var isVideoTexture:Bool = true;

    public function new(video:HtmlVideoElement, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Float) {
        super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.minFilter = if (minFilter != null) minFilter else LinearFilter;
        this.magFilter = if (magFilter != null) magFilter else LinearFilter;

        this.generateMipmaps = false;

        var scope:VideoTexture = this;

        function updateVideo() {
            scope.needsUpdate = true;
            video.requestVideoFrameCallback(updateVideo);
        }

        if (Reflect.hasField(video, "requestVideoFrameCallback")) {
            video.requestVideoFrameCallback(updateVideo);
        }
    }

    public function clone():Texture {
        return Type.createInstance(Type.getClass(this), [this.image]).copy(this);
    }

    public function update() {
        var video:HtmlVideoElement = this.image;
        var hasVideoFrameCallback:Bool = Reflect.hasField(video, "requestVideoFrameCallback");

        if (!hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA) {
            this.needsUpdate = true;
        }
    }
}