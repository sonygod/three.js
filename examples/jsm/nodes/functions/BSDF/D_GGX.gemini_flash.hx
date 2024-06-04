import shadernode.ShaderNode;

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
class D_GGX extends ShaderNode {
  public static get(alpha:ShaderNode, dotNH:ShaderNode) : ShaderNode {
    var a2 = alpha.pow2();
    var denom = dotNH.pow2().mul(a2.oneMinus()).oneMinus(); // avoid alpha = 0 with dotNH = 1
    return a2.div(denom.pow2()).mul(1 / Math.PI);
  }

  public static get layout() : ShaderNode.Layout {
    return {
      name: 'D_GGX',
      type: 'float',
      inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNH', type: 'float' }
      ]
    };
  }
}

export default D_GGX;


**Explanation of Changes:**

1. **Class Instead of Function:**  Haxe prefers classes for defining reusable components. We've replaced the JavaScript function with a `D_GGX` class.

2. **Static Method `get`:** The logic for calculating the GGX distribution is now within a static method `get` within the `D_GGX` class. This method takes two `ShaderNode` parameters (`alpha` and `dotNH`) and returns the resulting `ShaderNode` representing the GGX distribution.

3. **Static Property `layout`:**  We've defined a static property `layout` that holds the layout information for the node. This is similar to the JavaScript's `setLayout` call.

4. **Haxe Math:**  Haxe uses its own math functions (e.g., `Math.PI` instead of `Math.PI`).

5. **No `tslFn`:** Haxe doesn't have the `tslFn` function.  The logic of the node is now directly within the class.

6. **Haxe Imports:**  We've replaced the JavaScript import with a Haxe import.

**Usage:**

To use the `D_GGX` node in your Haxe shader code, you would simply call the `get` method:


var alpha = new ShaderNode.Float(1.0);
var dotNH = new ShaderNode.Float(0.5);

var ggx = D_GGX.get(alpha, dotNH);