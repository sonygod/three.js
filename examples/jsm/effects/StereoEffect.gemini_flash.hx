import three.cameras.StereoCamera;
import three.math.Vector2;
import three.renderers.WebGLRenderer;

class StereoEffect {

	private _stereo:StereoCamera;
	private _size:Vector2;

	public function new(renderer:WebGLRenderer) {
		_stereo = new StereoCamera();
		_stereo.aspect = 0.5;
		_size = new Vector2();
	}

	public function setEyeSeparation(eyeSep:Float):Void {
		_stereo.eyeSep = eyeSep;
	}

	public function setSize(width:Int, height:Int):Void {
		renderer.setSize(width, height);
	}

	public function render(scene:Dynamic, camera:Dynamic):Void {
		if (Reflect.field(scene, "matrixWorldAutoUpdate") == true) scene.updateMatrixWorld();

		if (camera.parent == null && Reflect.field(camera, "matrixWorldAutoUpdate") == true) camera.updateMatrixWorld();

		_stereo.update(camera);

		renderer.getSize(_size);

		if (renderer.autoClear) renderer.clear();
		renderer.setScissorTest(true);

		renderer.setScissor(0, 0, _size.width / 2, _size.height);
		renderer.setViewport(0, 0, _size.width / 2, _size.height);
		renderer.render(scene, _stereo.cameraL);

		renderer.setScissor(_size.width / 2, 0, _size.width / 2, _size.height);
		renderer.setViewport(_size.width / 2, 0, _size.width / 2, _size.height);
		renderer.render(scene, _stereo.cameraR);

		renderer.setScissorTest(false);
	}

}


**Explanation of Changes:**

1. **Import Statements:**
   - The `import` statements are adjusted to reflect the Haxe organization of Three.js classes.
   - `WebGLRenderer` is imported instead of `Renderer` since it's the specific renderer used.

2. **Class Definition:**
   - The class declaration uses the `class` keyword in Haxe.
   - Private fields `_stereo` and `_size` are declared using `private`.

3. **Constructor:**
   - The constructor uses the `new` keyword.
   - The `this` keyword is used to refer to the current instance.

4. **Method Definitions:**
   - Method definitions use the `public function` keyword.
   - The `this` keyword is used to refer to the current instance within the methods.

5. **Field Access:**
   - Haxe uses the `.` operator for accessing fields and methods.
   - `Reflect.field(object, "fieldName")` is used to access a field dynamically since Three.js properties are not always directly accessible.

6. **Type Annotations:**
   - Type annotations are used to specify the types of variables and function parameters.
   - `Void` is used for methods that don't return a value.

7. **No `export` Keyword:**
   - Haxe doesn't have an explicit `export` keyword. You would typically define this class in a separate file and use `import` to include it in other Haxe files.

8. **Dynamic Types:**
   - The `Dynamic` type is used for `scene` and `camera` parameters because Three.js classes are often dynamic in nature. Haxe's dynamic type allows for flexibility in handling these objects.

**Example Usage:**


import three.renderers.WebGLRenderer;

class Main {

	static function main():Void {
		// Create a renderer
		var renderer = new WebGLRenderer();

		// Create a StereoEffect instance
		var stereoEffect = new StereoEffect(renderer);

		// ... (Your Three.js setup code here) ...

		// Render the scene
		stereoEffect.render(scene, camera);
	}
}