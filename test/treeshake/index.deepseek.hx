import js.Browser;
import three.js.THREE;

class Main {
    static function main() {
        var camera:THREE.PerspectiveCamera;
        var scene:THREE.Scene;
        var renderer:THREE.WebGLRenderer;

        init(camera, scene, renderer);
    }

    static function init(camera:THREE.PerspectiveCamera, scene:THREE.Scene, renderer:THREE.WebGLRenderer) {
        camera = new THREE.PerspectiveCamera(70, Browser.window.innerWidth / Browser.window.innerHeight, 0.01, 10);

        scene = new THREE.Scene();

        renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(Browser.window.innerWidth, Browser.window.innerHeight);
        renderer.setAnimationLoop(animation);
        Browser.document.body.appendChild(renderer.domElement);
    }

    static function animation() {
        renderer.render(scene, camera);
    }
}