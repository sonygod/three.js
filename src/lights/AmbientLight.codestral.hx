import Light from Light;

class AmbientLight extends Light {

	function new(color:Int, intensity:Float) {
		super(color, intensity);

		this.isAmbientLight = true;
		this.type = 'AmbientLight';
	}
}


Please note that since Haxe is a statically typed language, the data types of the `color` and `intensity` properties are not the same as in JavaScript. You may need to adjust the types according to your needs. In this example, I've assumed that `color` is an `Int` and `intensity` is a `Float`.

Also, keep in mind that Haxe doesn't have a direct equivalent to JavaScript's `export` keyword. If you're using Haxe for a browser environment, you might want to use the `@:jsRequire` metadata to make your class accessible to JavaScript, like so:


@:jsRequire("three.js/src/lights/AmbientLight.hx")
class AmbientLight extends Light {
    // ...
}