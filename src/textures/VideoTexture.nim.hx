import three.constants.LinearFilter;
import three.textures.Texture;

class VideoTexture extends Texture {

    public var isVideoTexture:Bool = true;

    public var minFilter:LinearFilter;
    public var magFilter:LinearFilter;

    public var generateMipmaps:Bool = false;

    public function new(video:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic) {

        super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.minFilter = minFilter !== null ? minFilter : LinearFilter.Linear;
        this.magFilter = magFilter !== null ? magFilter : LinearFilter.Linear;

        var scope = this;

        function updateVideo() {

            scope.needsUpdate = true;
            if ('requestVideoFrameCallback' in video) {
                video.requestVideoFrameCallback(updateVideo);
            }

        }

        if ('requestVideoFrameCallback' in video) {
            video.requestVideoFrameCallback(updateVideo);
        }

    }

    public function clone():VideoTexture {

        return new VideoTexture(this.image).copy(this);

    }

    public function update() {

        var video = this.image;
        var hasVideoFrameCallback = 'requestVideoFrameCallback' in video;

        if (hasVideoFrameCallback === false && video.readyState >= video.HAVE_CURRENT_DATA) {

            this.needsUpdate = true;

        }

    }

}

export default VideoTexture;