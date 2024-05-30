package three.js.examples.jsm.renderers.common.nodes;

import three.js.examples.jsm.renderers.common.SampledTexture;

class NodeSampledTexture extends SampledTexture {
  public var textureNode:Dynamic;

  public function new(name:String, textureNode:Dynamic) {
    super(name, textureNode != null ? textureNode.value : null);
    this.textureNode = textureNode;
  }

  public var needsBindingsUpdate(get, never):Bool;

  private function get_needsBindingsUpdate():Bool {
    return this.textureNode.value != this.texture || super.needsBindingsUpdate;
  }

  public function update():Bool {
    var textureNode:Dynamic = this.textureNode;
    if (this.texture != textureNode.value) {
      this.texture = textureNode.value;
      return true;
    }
    return super.update();
  }
}

class NodeSampledCubeTexture extends NodeSampledTexture {
  public var isSampledCubeTexture:Bool;

  public function new(name:String, textureNode:Dynamic) {
    super(name, textureNode);
    this.isSampledCubeTexture = true;
  }
}