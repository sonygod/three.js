import three.js.*;

class Main {
  static var camera:PerspectiveCamera;
  static var scene:Scene;
  static var renderer:WebGLRenderer;

  static function main() {
    init();
  }

  static function init() {
    camera = new PerspectiveCamera(70, js.Lib.window.innerWidth / js.Lib.window.innerHeight, 0.01, 10);

    scene = new Scene();

    renderer = new WebGLRenderer({ antialias: true });
    renderer.setSize(js.Lib.window.innerWidth, js.Lib.window.innerHeight);
    renderer.setAnimationLoop(animation);
    js.Lib.document.body.appendChild(renderer.domElement);
  }

  static function animation() {
    renderer.render(scene, camera);
  }
}