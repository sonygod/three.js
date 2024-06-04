import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class TechnicolorShader extends Shader {

  public static var name:String = 'TechnicolorShader';

  public function new() {
    super();

    this.vertexShader = 
      "varying vec2 vUv;\n" +
      "\n" +
      "void main() {\n" +
      "\n" +
      "  vUv = uv;\n" +
      "  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
      "\n" +
      "}";

    this.fragmentShader = 
      "uniform sampler2D tDiffuse;\n" +
      "varying vec2 vUv;\n" +
      "\n" +
      "void main() {\n" +
      "\n" +
      "  vec4 tex = texture2D( tDiffuse, vec2( vUv.x, vUv.y ) );\n" +
      "  vec4 newTex = vec4(tex.r, (tex.g + tex.b) * .5, (tex.g + tex.b) * .5, 1.0);\n" +
      "\n" +
      "  gl_FragColor = newTex;\n" +
      "\n" +
      "}";

    this.addInput(new ShaderInput("tDiffuse", ShaderParameter.Sampler2D, null));
  }

}


**Explanation:**

* **Import Statements:** We import the necessary classes from the `openfl.display` package to work with shaders.
* **Class Definition:** The `TechnicolorShader` class extends the `Shader` class.
* **`name` Property:** The static `name` property is defined for reference.
* **Constructor:**
   * The constructor calls the superclass constructor to initialize the base Shader object.
   * It sets the `vertexShader` and `fragmentShader` strings to the GLSL code provided in the JavaScript example.
   * Finally, it uses `addInput` to add a uniform input named "tDiffuse" of type `ShaderParameter.Sampler2D` to the shader. This input will be used to pass the texture to the shader.

**Usage:**

You can use this shader in your Haxe project similar to how you would use any other shader. For instance, you could apply it to a `Sprite` object:


import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

class Main extends Sprite {

  public static function main() {
    new Main();
  }

  public function new() {
    super();

    // Load your texture (replace with your own image)
    var bitmapData:BitmapData = new BitmapData(100, 100);
    bitmapData.draw(new Bitmap(Assets.getBitmap("myTexture.png")));

    // Create a Sprite and apply the shader
    var sprite:Sprite = new Sprite();
    sprite.graphics.beginBitmapFill(bitmapData);
    sprite.graphics.drawRect(0, 0, 100, 100);
    sprite.graphics.endFill();
    sprite.shader = new TechnicolorShader();
    addChild(sprite);
  }
}