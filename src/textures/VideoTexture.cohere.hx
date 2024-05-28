import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.events.EventDispatcher;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class VideoTexture extends openfl.display.Texture {
    public var isVideoTexture:Bool;
    public var generateMipmaps:Bool;
    public var needsUpdate:Bool;

    public function new(video:Video, ?mapping:openfl.display.BitmapData, ?wrapS:Int, ?wrapT:Int, ?magFilter:Int, ?minFilter:Int, ?format:String, ?type:Int, ?anisotropy:Int) {
        super(video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
        isVideoTexture = true;
        minFilter = minFilter.default(openfl.display.TextureFilter.LINEAR);
        magFilter = magFilter.default(openfl.display.TextureFilter.LINEAR);
        generateMipmaps = false;
        needsUpdate = false;

        var scope = this;
        function updateVideo() {
            scope.needsUpdate = true;
            video.requestVideoFrameCallback(updateVideo);
        }

        if (Reflect.hasField(video, "requestVideoFrameCallback")) {
            video.requestVideoFrameCallback(updateVideo);
        }
    }

    public function clone():VideoTexture {
        return new VideoTexture(image).copy(this);
    }

    public function update() {
        var video = image;
        var hasVideoFrameCallback = Reflect.hasField(video, "requestVideoFrameCallback");

        if (!hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA) {
            needsUpdate = true;
        }
    }
}