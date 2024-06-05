import ViewportTextureNode from "./ViewportTextureNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import ViewportNode from "./ViewportNode";
import three.textures.FramebufferTexture;

class ViewportSharedTextureNode extends ViewportTextureNode {

  static var _sharedFramebuffer:FramebufferTexture = null;

  public function new(uvNode:ShaderNode = ViewportNode.viewportTopLeft, levelNode:ShaderNode = null) {
    if (_sharedFramebuffer == null) {
      _sharedFramebuffer = new FramebufferTexture();
    }
    super(uvNode, levelNode, _sharedFramebuffer);
  }

  public function updateReference():ViewportSharedTextureNode {
    return this;
  }

}

var viewportSharedTexture = ShaderNode.nodeProxy(ViewportSharedTextureNode);

Node.addNodeElement("viewportSharedTexture", viewportSharedTexture);

Node.addNodeClass("ViewportSharedTextureNode", ViewportSharedTextureNode);

export { ViewportSharedTextureNode, viewportSharedTexture };


Here's a breakdown of the changes:

**1. Imports:**

* `import ViewportTextureNode from "./ViewportTextureNode";` remains the same.
* `import { addNodeClass } from '../core/Node.js';`  is changed to `import Node from "../core/Node";`. This assumes that `Node` class is directly accessible, not within a module. 
* `import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';` is changed to `import ShaderNode from "../shadernode/ShaderNode";`.  Similarly, this assumes `nodeProxy` and `addNodeElement` are directly accessible within `ShaderNode`.
* `import { viewportTopLeft } from './ViewportNode.js';` is changed to `import ViewportNode from "./ViewportNode";`. Assuming `viewportTopLeft` is a static property of `ViewportNode`.
* `import { FramebufferTexture } from 'three';` is changed to `import three.textures.FramebufferTexture;`. Assuming Haxe is using Three.js bindings where `FramebufferTexture` exists within the `three` package.

**2. Static Variable:**

* `let _sharedFramebuffer = null;` is changed to `static var _sharedFramebuffer:FramebufferTexture = null;`. Haxe uses `static var` to declare static variables within a class. 

**3. Constructor:**

* `if ( _sharedFramebuffer === null ) { ... }` is changed to `if (_sharedFramebuffer == null) { ... }`. Haxe uses `==` for equality comparison.
* `super( uvNode, levelNode, _sharedFramebuffer );` remains the same.

**4. Method:**

* `updateReference() { ... }` remains the same, but with the return type specified as `ViewportSharedTextureNode`.

**5. Exports:**

*  `export default ViewportSharedTextureNode;` is changed to `export { ViewportSharedTextureNode, viewportSharedTexture };`. Haxe uses curly braces for exporting multiple items.

**6.  Node Access:**

* `addNodeElement( 'viewportSharedTexture', viewportSharedTexture );` and `addNodeClass( 'ViewportSharedTextureNode', ViewportSharedTextureNode );` are changed to:

   
   Node.addNodeElement("viewportSharedTexture", viewportSharedTexture);
   Node.addNodeClass("ViewportSharedTextureNode", ViewportSharedTextureNode);