import three.FileLoader;
import three.Loader;
import three.CanvasTexture;
import three.NearestFilter;
import three.SRGBColorSpace;
import lottie.Lottie;

class LottieLoader extends Loader {

    private var _quality:Float = 1;

    public function setQuality(value:Float):Void {
        this._quality = value;
    }

    public function load(url:String, onLoad:(texture:CanvasTexture) -> Void, onProgress:(event:ProgressEvent) -> Void, onError:(event:ErrorEvent) -> Void):CanvasTexture {

        var quality = this._quality || 1;

        var texture = new CanvasTexture();
        texture.minFilter = NearestFilter.Linear;
        texture.colorSpace = SRGBColorSpace.SRGB;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function (text) {

            var data:Dynamic = haxe.json.Json.parse(text);

            var container = js.Browser.document.createElement("div");
            container.style.width = data.w + "px";
            container.style.height = data.h + "px";
            js.Browser.document.body.appendChild(container);

            var animation = Lottie.loadAnimation({
                container: container,
                animType: "canvas",
                loop: true,
                autoplay: true,
                animationData: data,
                rendererSettings: { dpr: quality }
            });

            texture.animation = animation;
            texture.image = animation.container;

            animation.addEventListener("enterFrame", function () {
                texture.needsUpdate = true;
            });

            container.style.display = "none";

            if (onLoad != null) {
                onLoad(texture);
            }

        }, onProgress, onError);

        return texture;
    }
}