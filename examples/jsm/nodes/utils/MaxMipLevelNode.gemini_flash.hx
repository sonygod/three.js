import UniformNode from "../core/UniformNode";
import NodeUpdateType from "../core/constants";
import ShaderNode from "../shadernode/ShaderNode";
import Node from "../core/Node";

class MaxMipLevelNode extends UniformNode {
  public textureNode:ShaderNode;

  public function new(textureNode:ShaderNode) {
    super(0);
    this.textureNode = textureNode;
    this.updateType = NodeUpdateType.FRAME;
  }

  public function get texture():Dynamic {
    return this.textureNode.value;
  }

  public function update() {
    var texture = this.texture;
    var images = cast texture.images;
    var image = if (images != null && images.length > 0) {
      if (images[0] != null && images[0].image != null) {
        images[0].image
      } else {
        images[0]
      }
    } else {
      texture.image
    };

    if (image != null && Reflect.hasField(image, "width")) {
      var width = image.width;
      var height = image.height;
      this.value = Math.log2(Math.max(width, height));
    }
  }
}

var maxMipLevel = ShaderNode.nodeProxy(MaxMipLevelNode);

Node.addNodeClass("MaxMipLevelNode", MaxMipLevelNode);