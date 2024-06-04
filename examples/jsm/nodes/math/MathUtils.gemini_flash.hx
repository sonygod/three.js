import OperatorNode from "./OperatorNode";
import ShaderNode from "../shadernode/ShaderNode";
import MathNode from "./MathNode";

// remapping functions https://iquilezles.org/articles/functions/
class RemappingFunctions {
  public static parabola(x:OperatorNode, k:OperatorNode):OperatorNode {
    return MathNode.pow(OperatorNode.mul(4.0, x.mul(OperatorNode.sub(1.0, x))), k);
  }

  public static gain(x:OperatorNode, k:OperatorNode):OperatorNode {
    return x.lessThan(0.5) ? RemappingFunctions.parabola(x.mul(2.0), k).div(2.0) : OperatorNode.sub(1.0, RemappingFunctions.parabola(OperatorNode.mul(OperatorNode.sub(1.0, x), 2.0), k).div(2.0));
  }

  public static pcurve(x:OperatorNode, a:OperatorNode, b:OperatorNode):OperatorNode {
    return MathNode.pow(OperatorNode.div(MathNode.pow(x, a), OperatorNode.add(MathNode.pow(x, a), MathNode.pow(OperatorNode.sub(1.0, x), b))), 1.0 / a);
  }

  public static sinc(x:OperatorNode, k:OperatorNode):OperatorNode {
    return MathNode.sin(MathNode.PI.mul(k.mul(x).sub(1.0))).div(MathNode.PI.mul(k.mul(x).sub(1.0)));
  }
}

ShaderNode.addNodeElement("parabola", RemappingFunctions.parabola);
ShaderNode.addNodeElement("gain", RemappingFunctions.gain);
ShaderNode.addNodeElement("pcurve", RemappingFunctions.pcurve);
ShaderNode.addNodeElement("sinc", RemappingFunctions.sinc);


**Explanation of Changes:**

1. **Class Structure:**  Haxe encourages using classes for organization. We create a `RemappingFunctions` class to group the functions.
2. **Static Methods:** Instead of separate functions, we use static methods within the class. This is the standard way to create functions associated with a class in Haxe.
3. **Haxe Syntax:** We adjust the syntax to Haxe's conventions. This includes using `:` for type declarations, `.` for accessing class members, and `public` for method visibility.
4. **Type Annotations:**  Haxe is statically typed, so we add type annotations to our methods (e.g., `x:OperatorNode`). This helps ensure type safety.
5. **Import Statements:** We import the necessary classes using the `import` keyword.
6. **addNodeElement:** We call the `addNodeElement` function from the `ShaderNode` class to register the functions with the shader node system.

**How to Use:**


// Example usage:
var x = new OperatorNode(1.0);
var k = new OperatorNode(2.0);

var parabolaResult = RemappingFunctions.parabola(x, k);