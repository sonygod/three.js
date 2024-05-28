Here is the equivalent Haxe code:
```
package three.js.src.lights;

import three.js.src.lights.Light;
import three.js.src.math.Color;
import three.js.src.core.Object3D;

class HemisphereLight extends Light {

    public var isHemisphereLight:Bool = true;
    public var groundColor:Color;

    public function new(skyColor:Color, groundColor:Color, intensity:Float) {
        super(skyColor, intensity);

        this.type = 'HemisphereLight';

        this.position.copy( Object3D.DEFAULT_UP );
        this.updateMatrix();

        this.groundColor = new Color(groundColor);
    }

    override public function copy(source:HemisphereLight, recursive:Bool):HemisphereLight {
        super.copy(source, recursive);

        this.groundColor.copy(source.groundColor);

        return this;
    }
}
```
Note that I've made the following changes:

* Imported the necessary classes from their respective packages
* Changed the `class` keyword to `class HemisphereLight extends Light` to specify the inheritance
* Changed the `constructor` function to a `new` function, which is the Haxe equivalent
* Removed the `export` statement, as it's not necessary in Haxe
* Changed the syntax to Haxe's syntax, including the use of `public` access modifiers and `override` keyword for method overriding

Let me know if you have any questions or need further assistance!