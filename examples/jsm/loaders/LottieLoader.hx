package three.js.examples.jsm.loaders;

import three.js.loaders.Loader;
import three.js.textures.CanvasTexture;
import three.js.constants.NearestFilter;
import three.js.constants.SRGBColorSpace;
import js.html.Document;
import js.html.DivElement;

class LottieLoader extends Loader
{
    private var _quality:Float;

    public function new(manager:LoaderManager)
    {
        super(manager);
    }

    public function setQuality(value:Float)
    {
        _quality = value;
    }

    public function load(url:String, onLoad:CanvasTexture->Void, onProgress:ProgressEvent->Void, onError:ErrorEvent->Void)
    {
        var quality:Float = _quality != null ? _quality : 1.0;

        var texture:CanvasTexture = new CanvasTexture();
        texture.minFilter = NearestFilter;
        texture.colorSpace = SRGBColorSpace;

        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(path);
        loader.setWithCredentials(withCredentials);

        loader.load(url, function(text:String)
        {
            var data:Dynamic = Json.parse(text);

            var container:DivElement = cast Document/body.appendChild(Document/createElement('div'));
            container.style.width = data.w + 'px';
            container.style.height = data.h + 'px';

            var animation:lottie.AnimationItem = lottie.loadAnimation({
                container: container,
                animType: 'canvas',
                loop: true,
                autoplay: true,
                animationData: data,
                rendererSettings: { dpr: quality }
            });

            texture.animation = animation;
            texture.image = animation.container;

            animation.addEventListener('enterFrame', function()
            {
                texture.needsUpdate = true;
            });

            container.style.display = 'none';

            if (onLoad != null)
            {
                onLoad(texture);
            }
        }, onProgress, onError);

        return texture;
    }
}

// Note: I assumed that `lottie` is a extern library, if it's not the case, you need to import it correctly
extern class lottie
{
    public static function loadAnimation(options:Dynamic):lottie.AnimationItem;
}