package three.textures;

import three.constants.LinearFilter;
import three.textures.Texture;

class VideoTexture extends Texture {
    public var isVideoTexture:Bool = true;

    public function new(video:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic = null, minFilter:Dynamic = null, format:Dynamic = null, type:Dynamic = null, anisotropy:Dynamic = null) {
        super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.minFilter = if (minFilter != null) minFilter else LinearFilter;
        this.magFilter = if (magFilter != null) magFilter else LinearFilter;

        this.generateMipmaps = false;

        var scope:VideoTexture = this;

        function updateVideo():Void {
            scope.needsUpdate = true;
            video.requestVideoFrameCallback(updateVideo);
        }

        if (Reflect.hasField(video, "requestVideoFrameCallback")) {
            video.requestVideoFrameCallback(updateVideo);
        }
    }

    public function clone():Texture {
        return new VideoTexture(this.image).copy(this);
    }

    public function update():Void {
        var video:Dynamic = this.image;
        var hasVideoFrameCallback:Bool = Reflect.hasField(video, "requestVideoFrameCallback");

        if (!hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA) {
            this.needsUpdate = true;
        }
    }
}