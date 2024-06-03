class Glsl {
  static function glsl(code:String) {
    return code;
  }
}

export default Glsl.glsl(`
vec4 mvPosition = vec4( transformed, 1.0 );

#ifdef USE_BATCHING

	mvPosition = batchingMatrix * mvPosition;

#endif

#ifdef USE_INSTANCING

	mvPosition = instanceMatrix * mvPosition;

#endif

mvPosition = modelViewMatrix * mvPosition;

gl_Position = projectionMatrix * mvPosition;
`);


**Explanation:**

1. **Haxe Class:** We create a `Glsl` class to hold the glsl string. This is for better organization and readability.
2. **`glsl` Function:** The `glsl` function is a static function that takes a `String` as input and returns the same string. This is a simple way to mark the code as GLSL within your Haxe code.
3. **Exporting:** We export the `glsl` function from the file so it can be used in other parts of your project.
4. **`#ifdef` Directives:** Haxe doesn't have preprocessor directives like `#ifdef`. You would need to use a different approach to handle conditional compilation, such as using `if` statements and defining constants at compile time.

**Example Usage:**


// Define a constant at compile time.
#if haxeTarget == "webgl"
  const USE_INSTANCING = true;
#else
  const USE_INSTANCING = false;
#endif

// Use the glsl function.
var shaderCode = Glsl.glsl(`
  vec4 mvPosition = vec4( transformed, 1.0 );

  #if USE_INSTANCING
    mvPosition = instanceMatrix * mvPosition;
  #end

  mvPosition = modelViewMatrix * mvPosition;

  gl_Position = projectionMatrix * mvPosition;
`);

// Use the shaderCode string.
// ...