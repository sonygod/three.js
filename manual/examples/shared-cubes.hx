Here is the converted Haxe code:
```
package;

import js.three.*;

class SharedCubes {
  static public var state = {
    width: 300, // canvas default
    height: 150, // canvas default
  };

  static public function init(data:Dynamic) {
    var canvas:HTMLCanvasElement = data.canvas;
    var renderer:WebGLRenderer = new WebGLRenderer({ antialias: true, canvas: canvas });
    state.width = canvas.width;
    state.height = canvas.height;

    var fov:Float = 75;
    var aspect:Float = 2; // the canvas default
    var near:Float = 0.1;
    var far:Float = 100;
    var camera:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
    camera.position.z = 4;

    var scene:Scene = new Scene();

    {
      var color:Int = 0xFFFFFF;
      var intensity:Float = 1;
      var light:DirectionalLight = new DirectionalLight(color, intensity);
      light.position.set(-1, 2, 4);
      scene.add(light);
    }

    var boxWidth:Float = 1;
    var boxHeight:Float = 1;
    var boxDepth:Float = 1;
    var geometry:BoxGeometry = new BoxGeometry(boxWidth, boxHeight, boxDepth);

    function makeInstance(geometry:Geometry, color:Int, x:Float) {
      var material:MeshPhongMaterial = new MeshPhongMaterial({ color: color });
      var cube:Mesh = new Mesh(geometry, material);
      scene.add(cube);
      cube.position.x = x;
      return cube;
    }

    var cubes:Array<Mesh> = [
      makeInstance(geometry, 0x44aa88, 0),
      makeInstance(geometry, 0x8844aa, -2),
      makeInstance(geometry, 0xaa8844, 2),
    ];

    function resizeRendererToDisplaySize(renderer:WebGLRenderer) {
      var canvas:HTMLCanvasElement = renderer.domElement;
      var width:Int = state.width;
      var height:Int = state.height;
      var needResize:Bool = canvas.width != width || canvas.height != height;
      if (needResize) {
        renderer.setSize(width, height, false);
      }
      return needResize;
    }

    function render(time:Float) {
      time *= 0.001;
      if (resizeRendererToDisplaySize(renderer)) {
        camera.aspect = state.width / state.height;
        camera.updateProjectionMatrix();
      }

      for (cube in cubes) {
        var speed:Float = 1 + cubes.indexOf(cube) * 0.1;
        var rot:Float = time * speed;
        cube.rotation.x = rot;
        cube.rotation.y = rot;
      }

      renderer.render(scene, camera);
      js.Browser.window.requestAnimationFrame(render);
    }

    js.Browser.window.requestAnimationFrame(render);
  }
}
```
Note: 

1. I assumed that the Haxe project is targeting JavaScript, so I used the `js` package for the JavaScript-specific classes and functions.
2. I replaced the `import` statements with Haxe's `import` statements, and removed the `export` statements since they are not necessary in Haxe.
3. I replaced the `THREE` namespace with `js.three`, assuming that the Three.js library is included in the Haxe project.
4. I replaced the JavaScript `requestAnimationFrame` function with `js.Browser.window.requestAnimationFrame`, which is the Haxe equivalent.
5. I replaced the JavaScript `canvas` object with `HTMLCanvasElement`, which is the Haxe type for a canvas element.
6. I replaced the JavaScript `Function` type with `Dynamic`, which is the Haxe type for a dynamic function.

Please note that this conversion is not 100% automatic, and some manual adjustments may be necessary to ensure that the Haxe code works correctly.