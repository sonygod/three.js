Here is the converted Haxe code:
```
package threejs.src.lights;

import threejs.src.core.Object3D;
import threejs.src.lights.Light;
import threejs.src.lights.DirectionalLightShadow;

class DirectionalLight extends Light {
    public var isDirectionalLight:Bool;
    public var target:Object3D;
    public var shadow:DirectionalLightShadow;

    public function new(color:Int, intensity:Float) {
        super(color, intensity);

        isDirectionalLight = true;
        type = 'DirectionalLight';

        position.copy(Object3D.DEFAULT_UP);
        updateMatrix();

        target = new Object3D();
        shadow = new DirectionalLightShadow();
    }

    public function dispose():Void {
        shadow.dispose();
    }

    public function copy(source:DirectionalLight):DirectionalLight {
        super.copy(source);

        target = source.target.clone();
        shadow = source.shadow.clone();

        return this;
    }
}
```
Note that I've made the following assumptions:

* `Object3D` and `DirectionalLightShadow` are already defined in Haxe, and are part of the `threejs.src.core` and `threejs.src.lights` packages, respectively.
* `Light` is also already defined in Haxe, and is part of the `threejs.src.lights` package.
* I've used the `:Bool` syntax to specify the type of the `isDirectionalLight` variable, but you can adjust this to use a different type if needed.
* I've used the `:Int` and `:Float` syntax to specify the types of the `color` and `intensity` parameters, respectively, but you can adjust these to use different types if needed.

Let me know if you have any questions or need further assistance!