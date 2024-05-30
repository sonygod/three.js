package three.js.examples.javascript.renderers.common;

import js.html.WebGLRenderingContext;
import three.js.nodes.Nodes;
import three.js.objects.QuadMesh;

class PostProcessing {
  public var renderer:WebGLRenderingContext;
  public var outputNode: Vec4;

  public function new(renderer:WebGLRenderingContext, ?outputNode:Vec4) {
    this.renderer = renderer;
    this.outputNode = if (outputNode != null) outputNode else new Vec4(0, 0, 1, 1);
  }

  public function render() {
    quadMesh.material.fragmentNode = outputNode;
    quadMesh.render(renderer);
  }

  public function renderAsync():Promise<Void> {
    quadMesh.material.fragmentNode = outputNode;
    return quadMesh.renderAsync(renderer);
  }

  static var quadMesh:QuadMesh = new QuadMesh(new NodeMaterial());

  public static function main() {}
}