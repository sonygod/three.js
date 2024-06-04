import three.Three;
import three.core.Object3D;
import three.core.Geometry;
import three.core.Mesh;
import three.core.Scene;
import three.core.Camera;
import three.core.Group;
import three.materials.MeshMatcapMaterial;
import three.materials.Color;
import three.textures.Texture;
import three.textures.CanvasTexture;
import three.geometries.IcosahedronGeometry;
import three.loaders.ImageBitmapLoader;
import three.renderers.WebGLRenderer;
import three.scenes.Fog;
import three.cameras.PerspectiveCamera;

class MatcapIcosahedrons {
  var camera:PerspectiveCamera;
  var scene:Scene;
  var renderer:WebGLRenderer;
  var group:Group;
  var seed:Int = 1;

  public function new(canvas:Dynamic, width:Int, height:Int, pixelRatio:Float, path:String) {
    camera = new PerspectiveCamera(40, width / height, 1, 1000);
    camera.position.z = 200;

    scene = new Scene();
    scene.fog = new Fog(0x444466, 100, 400);
    scene.background = new Color(0x444466);

    group = new Group();
    scene.add(group);

    var loader = new ImageBitmapLoader().setPath(path);
    loader.setOptions({imageOrientation: "flipY"});
    loader.load('textures/matcaps/matcap-porcelain-white.jpg', function(imageBitmap:Dynamic) {
      var texture = new CanvasTexture(imageBitmap);

      var geometry = new IcosahedronGeometry(5, 8);
      var materials = [
        new MeshMatcapMaterial({color: 0xaa24df, matcap: texture}),
        new MeshMatcapMaterial({color: 0x605d90, matcap: texture}),
        new MeshMatcapMaterial({color: 0xe04a3f, matcap: texture}),
        new MeshMatcapMaterial({color: 0xe30456, matcap: texture})
      ];

      for (i in 0...100) {
        var material = materials[i % materials.length];
        var mesh = new Mesh(geometry, material);
        mesh.position.x = random() * 200 - 100;
        mesh.position.y = random() * 200 - 100;
        mesh.position.z = random() * 200 - 100;
        mesh.scale.setScalar(random() + 1);
        group.add(mesh);
      }

      renderer = new WebGLRenderer({antialias: true, canvas: canvas});
      renderer.setPixelRatio(pixelRatio);
      renderer.setSize(width, height, false);

      animate();
    });
  }

  function animate() {
    group.rotation.y = -Date.now() / 4000;
    renderer.render(scene, camera);
    if (js.Lib.is(js.Lib.window, "requestAnimationFrame")) {
      js.Lib.window.requestAnimationFrame(animate);
    }
  }

  function random() {
    var x = Math.sin(seed++) * 10000;
    return x - Math.floor(x);
  }
}

class Main {
  static function main() {
    // Replace with your actual canvas element and path
    var canvas = js.Lib.window.document.getElementById("canvas");
    var path = "path/to/your/textures";
    var init = new MatcapIcosahedrons(canvas, 800, 600, 1, path);
  }
}