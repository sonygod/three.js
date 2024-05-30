import three.js.extras.core.Object3D;
import three.js.extras.geometries.SphereGeometry;
import three.js.extras.materials.MeshBasicMaterial;
import three.js.extras.objects.Mesh;
import three.js.math.Vector3;
import three.js.math.Quaternion;
import three.js.scenes.Scene;
import three.js.cameras.PerspectiveCamera;
import three.js.renderers.WebGLRenderer;
import three.js.core.BufferGeometry;
import three.js.core.BufferAttribute;
import three.js.extras.helpers.AxesHelper;
import three.js.extras.helpers.GridHelper;

class Main {
    static function main() {
        var scene = new Scene();
        var camera = new PerspectiveCamera(75, 800 / 600, 0.1, 1000);
        var renderer = new WebGLRenderer();

        renderer.setSize(800, 600);
        document.body.appendChild(renderer.domElement);

        var geometry = new SphereGeometry(1, 32, 32);
        var material = new MeshBasicMaterial({color: 0xFF0000});
        var sphere = new Mesh(geometry, material);
        scene.add(sphere);

        camera.position.z = 5;

        var animate = function() {
            requestAnimationFrame(animate);
            sphere.rotation.x += 0.01;
            sphere.rotation.y += 0.01;
            renderer.render(scene, camera);
        };

        animate();
    }
}