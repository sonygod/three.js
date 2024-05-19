package three.test.treeshake;

import three.*;

class Index {
    static var camera:PerspectiveCamera;
    static var scene:Scene;
    static var renderer:WebGLRenderer;

    static function init() {
        camera = new PerspectiveCamera(70, Lib.window.innerWidth / Lib.window.innerHeight, 0.01, 10);

        scene = new Scene();

        renderer = new WebGLRenderer({antialias:true});
        renderer.setSize(Lib.window.innerWidth, Lib.window.innerHeight);
        renderer.domElement.addEventListener("dblclick", function(_) {});
        untyped __js__("document.body.appendChild({0})", renderer.domElement);
        renderer.setAnimationLoop(animation);
    }

    static function animation() {
        renderer.render(scene, camera);
    }

    static function main() {
        init();
    }
}