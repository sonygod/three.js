import js.three.*;
import js.Browser.window;

class Main {
    static function main() {
        var camera:PerspectiveCamera;
        var scene:Scene;
        var renderer:WebGLRenderer;

        init();

        function init() {
            camera = new PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 10);
            scene = new Scene();
            renderer = new WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.setAnimationLoop(animation);
            window.document.body.appendChild(renderer.domElement);
        }

        function animation() {
            renderer.render(scene, camera);
        }
    }
}