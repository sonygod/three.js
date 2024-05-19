import js.html.Document;
import js.Browser;
import three.js.*;

class Main {
    static var camera:PerspectiveCamera;
    static var scene:Scene;
    static var renderer:WebGLRenderer;

    static function main():Void {
        init();
    }

    static function init():Void {
        camera = new PerspectiveCamera(70, Browser.window.innerWidth / Browser.window.innerHeight, 0.01, 10);
        scene = new Scene();
        renderer = new WebGLRenderer({ antialias: true });
        renderer.setSize(Browser.window.innerWidth, Browser.window.innerHeight);
        renderer.domElement.addEventListener("webglcontextlost", function(_) {
            // handle context lost
        });
        renderer.domElement.addEventListener("webglcontextrestored", function(_) {
            animation();
        });
        Document.body.appendChild(renderer.domElement);
        animation();
    }

    static function animation():Void {
        renderer.render(scene, camera);
    }
}