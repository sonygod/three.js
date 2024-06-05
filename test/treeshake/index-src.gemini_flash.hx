import three.core.PerspectiveCamera;
import three.core.Scene;
import three.renderers.WebGLRenderer;

class Main {

  static var camera:PerspectiveCamera;
  static var scene:Scene;
  static var renderer:WebGLRenderer;

  static function main() {
    init();
  }

  static function init() {
    camera = new PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 10);

    scene = new Scene();

    renderer = new WebGLRenderer(antialias: true);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setAnimationLoop(animation);
    document.body.appendChild(renderer.domElement);
  }

  static function animation() {
    renderer.render(scene, camera);
  }

}