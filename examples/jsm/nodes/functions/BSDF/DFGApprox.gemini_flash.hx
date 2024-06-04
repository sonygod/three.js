import haxe.macro.Expr;
import shadernode.ShaderNode;
import shadernode.Vec2;
import shadernode.Vec4;
import shadernode.Float;

class DFGApprox extends ShaderNode {

  public static function new() : DFGApprox {
    return new DFGApprox();
  }

  override function getExpression() : Expr {
    return macro {
      var c0 = vec4(-1, -0.0275, -0.572, 0.022);
      var c1 = vec4(1, 0.0425, 1.04, -0.04);

      var r = roughness.mul(c0).add(c1);
      var a004 = r.x.mul(r.x).min(dotNV.mul(-9.28).exp2()).mul(r.x).add(r.y);
      var fab = vec2(-1.04, 1.04).mul(a004).add(r.zw);
      return fab;
    }
  }

  override function getLayout() : ShaderNode.Layout {
    return {
      name: 'DFGApprox',
      type: 'vec2',
      inputs: [
        { name: 'roughness', type: 'float' },
        { name: 'dotNV', type: 'vec3' }
      ]
    };
  }
}


**Explanation:**

1. **Imports:** We import the necessary classes from the `shadernode` package.
2. **DFGApprox Class:**
   - We define a class `DFGApprox` that extends `ShaderNode`.
   - The `new()` function creates a new instance of the class.
   - The `getExpression()` function returns the Haxe macro expression for the shader node's calculation.
   - The `getLayout()` function defines the node's metadata, including its name, type, and input parameters.

3. **Macro Expression:**
   - The `macro` keyword allows us to write Haxe code that will be expanded at compile time.
   - We define the constants `c0` and `c1` as `Vec4` objects.
   - The expression calculates the `fab` vector using the provided `roughness` and `dotNV` inputs, following the same logic as the original JavaScript code.

4. **Layout:**
   - The `getLayout()` function specifies the node's name, type, and input parameters. The type is set to `vec2` to indicate the node's output is a 2-component vector.

**Usage:**

To use the `DFGApprox` node in your Haxe shader code, you would create an instance of the class and connect its inputs to the appropriate values:


var dfgApprox = DFGApprox.new();
dfgApprox.connectInput("roughness", roughnessValue);
dfgApprox.connectInput("dotNV", dotNVValue);


Then you can access the node's output as a `Vec2` object:


var result = dfgApprox.output;