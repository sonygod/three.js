package three.js.examples.jsm.loaders;

import thx.pools.NIL;
import thx.Text;
import thx.Arrays;
import js.html.DivElement;
import js.html.Document;
import js.html.CanvasElement;
import js.html.Image;

import three.FileLoader;
import three.Loader;
import three.CanvasTexture;
import three.NearestFilter;
import three.SRGBColorSpace;

import lottie.LottieAnimation;

class LottieLoader extends Loader {
  var _quality : Int;

  public function new() {
    super();
  }

  public function setQuality(value : Int) {
    _quality = value;
  }

  override public function load(url : String, onLoad : CanvasTexture->Void, onProgress : ProgressEventHandler, onError : ErrorEventHandler) {
    var quality : Int = _quality == null ? 1 : _quality;
    var texture : CanvasTexture = new CanvasTexture();
    texture.minFilter = NearestFilter;
    texture.colorSpace = SRGBColorSpace;

    var loader : FileLoader = new FileLoader(this.manager);
    loader.setPath(this.path);
    loader.setWithCredentials(this.withCredentials);

    loader.load(url, function(text : String) {
      var data : Dynamic = Json.parse(text);

      var container : DivElement = cast Document.body.appendChild(Element.create("div"));
      container.style.width = '${data.w}px';
      container.style.height = '${data.h}px';

      var animation : LottieAnimation = Lottie.loadAnimation({
        container: container,
        animType: 'canvas',
        loop: true,
        autoplay: true,
        animationData: data,
        rendererSettings: { dpr: quality }
      });

      texture.animation = animation;
      texture.image = animation.container;

      animation.addEventListener('enterFrame', function(_) {
        texture.needsUpdate = true;
      });

      container.style.display = 'none';

      if (onLoad != null) {
        onLoad(texture);
      }
    }, onProgress, onError);

    return texture;
  }
}

public class LottieLoader {
  static public function getInstance() {
    return new LottieLoader();
  }
}