import hxthreejs.THREE;
import hxthreejs.textures.TextureLoader;

class Main {
  public function new() {
    var loader = new TextureLoader();
    var textureResolve: Future<THREE.Texture>;
    var promise = new Promise<THREE.Texture>((resolve, reject) => {
      textureResolve = resolve;
    });
    var texture = loader.load(url, (texture) => {
      textureResolve.handle(texture);
    });
    return {
      texture: texture,
      promise: promise,
    };
  }
}