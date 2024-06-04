import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;

class MirrorShader extends Shader {

    public static var name:String = "MirrorShader";

    public var tDiffuse:ShaderInput;
    public var side:Int;

    public function new() {
        super();

        tDiffuse = new ShaderInput();
        side = 1;

        // Set up uniforms
        uniforms.set("tDiffuse", tDiffuse);
        uniforms.set("side", new ShaderParameter(side, ShaderParameterType.INT));

        // Set up vertex shader
        vertexSource =
            "varying vec2 vUv;\n" +
            "void main() {\n" +
            "  vUv = uv;\n" +
            "  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n" +
            "}";

        // Set up fragment shader
        fragmentSource =
            "uniform sampler2D tDiffuse;\n" +
            "uniform int side;\n" +
            "varying vec2 vUv;\n" +
            "void main() {\n" +
            "  vec2 p = vUv;\n" +
            "  if (side == 0) {\n" +
            "    if (p.x > 0.5) p.x = 1.0 - p.x;\n" +
            "  } else if (side == 1) {\n" +
            "    if (p.x < 0.5) p.x = 1.0 - p.x;\n" +
            "  } else if (side == 2) {\n" +
            "    if (p.y < 0.5) p.y = 1.0 - p.y;\n" +
            "  } else if (side == 3) {\n" +
            "    if (p.y > 0.5) p.y = 1.0 - p.y;\n" +
            "  }\n" +
            "  vec4 color = texture2D(tDiffuse, p);\n" +
            "  gl_FragColor = color;\n" +
            "}";
    }
}


**Explanation:**

1. **Import necessary classes:**
   - `openfl.display.Shader`:  Base class for shaders.
   - `openfl.display.ShaderInput`: Represents an input to the shader (like a texture).
   - `openfl.display.ShaderParameter`: Represents a parameter for the shader (like a uniform).
   - `openfl.display.ShaderParameterType`: Defines the type of a shader parameter.

2. **Create a class `MirrorShader`:**
   - Inherits from `Shader`.
   - Defines a static `name` property for the shader.

3. **Define shader inputs and parameters:**
   - `tDiffuse`: A `ShaderInput` to hold the texture.
   - `side`: An `Int` to control the mirroring side.

4. **Initialize the shader in the constructor:**
   - Call the superclass constructor.
   - Create a `ShaderInput` for `tDiffuse`.
   - Initialize `side` to 1 (right mirroring).
   - Set the uniforms using `uniforms.set()`:
     - `tDiffuse` is linked to the `ShaderInput` object.
     - `side` is set as a `ShaderParameter` with type `INT`.
   - Set the `vertexSource` and `fragmentSource` properties with the GLSL code. 

5. **GLSL code:**
   - The code is adapted from your JavaScript example.
   - `varying vec2 vUv;` is used to pass the texture coordinates from the vertex shader to the fragment shader.
   - The fragment shader uses the `side` uniform to determine which side of the texture to mirror.
   - The `texture2D()` function samples the texture based on the modified UV coordinates.

**How to use:**

1. Create an instance of `MirrorShader`.
2. Set the `tDiffuse` property to a texture object.
3. Set the `side` property to the desired side (0, 1, 2, or 3).
4. Apply the shader to a display object.

Here's an example:


import openfl.display.Sprite;
import openfl.display.Texture;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Stage;
import openfl.utils.Assets;

class Main extends Sprite {

    override function createChildren():Void {
        super.createChildren();

        // Load an image
        Assets.loadBitmap("path/to/your/image.png", function(bitmapData:BitmapData) {
            var texture:Texture = new Texture(bitmapData);

            // Create a sprite
            var sprite:Sprite = new Sprite();
            addChild(sprite);

            // Create the shader
            var mirrorShader:MirrorShader = new MirrorShader();
            mirrorShader.tDiffuse = texture;
            mirrorShader.side = 0;

            // Apply the shader
            sprite.shader = mirrorShader;

            // Create a bitmap to display the result
            var bitmap:Bitmap = new Bitmap(texture);
            addChild(bitmap);
        });
    }
}