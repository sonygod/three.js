package jsm.nodes.display;

import jsm.core.Node;
import jsm.shadernode.ShaderNode;
import jsm.accessors.CameraNode;
import jsm.accessors.PositionNode;
import jsm.nodes.display.ViewportDepthTextureNode;

@:expose
class ViewportDepthNode extends Node {
    public var scope: String;
    public var valueNode: Node;
    public var isViewportDepthNode: Bool = true;

    public function new(scope: String, valueNode: Node = null) {
        super('float');
        this.scope = scope;
        this.valueNode = valueNode;
    }

    override public function generate(builder: Builder): Dynamic {
        if(this.scope === ViewportDepthNode.DEPTH_PIXEL) {
            return builder.getFragDepth();
        }
        return super.generate(builder);
    }

    public function setup(): Node {
        var node: Node = null;
        if(this.scope === ViewportDepthNode.DEPTH) {
            node = viewZToOrthographicDepth(PositionNode.positionView.z, CameraNode.cameraNear, CameraNode.cameraFar);
        } else if(this.scope === ViewportDepthNode.DEPTH_TEXTURE) {
            var texture: Node = this.valueNode != null ? this.valueNode : ViewportDepthTextureNode.viewportDepthTexture();
            var viewZ = perspectiveDepthToViewZ(texture, CameraNode.cameraNear, CameraNode.cameraFar);
            node = viewZToOrthographicDepth(viewZ, CameraNode.cameraNear, CameraNode.cameraFar);
        } else if(this.scope === ViewportDepthNode.DEPTH_PIXEL) {
            if(this.valueNode != null) {
                node = depthPixelBase().assign(this.valueNode);
            }
        }
        return node;
    }

    static public function viewZToOrthographicDepth(viewZ: Node, near: Node, far: Node): Node {
        return viewZ.add(near).div(near.sub(far));
    }

    static public function orthographicDepthToViewZ(depth: Node, near: Node, far: Node): Node {
        return near.sub(far).mul(depth).sub(near);
    }

    static public function viewZToPerspectiveDepth(viewZ: Node, near: Node, far: Node): Node {
        return near.add(viewZ).mul(far).div(far.sub(near).mul(viewZ));
    }

    static public function perspectiveDepthToViewZ(depth: Node, near: Node, far: Node): Node {
        return near.mul(far).div(far.sub(near).mul(depth).sub(far));
    }

    static public var DEPTH: String = 'depth';
    static public var DEPTH_TEXTURE: String = 'depthTexture';
    static public var DEPTH_PIXEL: String = 'depthPixel';
}

@:expose
class DepthPixel {
    static public function assign(value: Node): Node {
        return ShaderNode.nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL)(value);
    }
}

ShaderNode.addNodeClass('ViewportDepthNode', ViewportDepthNode);