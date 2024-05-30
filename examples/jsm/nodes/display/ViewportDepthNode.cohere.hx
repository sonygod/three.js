import Node from '../core/Node.hx';
import { nodeImmutable, nodeProxy } from '../shadernode/ShaderNode.hx';
import { cameraNear, cameraFar } from '../accessors/CameraNode.hx';
import { positionView } from '../accessors/PositionNode.hx';
import { viewportDepthTexture } from './ViewportDepthTextureNode.hx';

class ViewportDepthNode extends Node {
    public scope: ViewportDepthNode.Scope;
    public valueNode: Node | null;
    public isViewportDepthNode: Bool = true;

    public function new(scope: ViewportDepthNode.Scope, valueNode: Node = null) {
        super('float');
        this.scope = scope;
        this.valueNode = valueNode;
    }

    public function generate(builder: Dynamic) -> String {
        if (this.scope == ViewportDepthNode.DEPTH_PIXEL) {
            return builder.getFragDepth();
        }
        return super.generate(builder);
    }

    public function setup(/*builder*/) -> Node {
        var node: Node = null;
        switch (this.scope) {
            case ViewportDepthNode.DEPTH:
                node = viewZToOrthographicDepth(positionView.z, cameraNear, cameraFar);
                break;
            case ViewportDepthNode.DEPTH_TEXTURE:
                var texture = (this.valueNode != null) ? this.valueNode : viewportDepthTexture();
                var viewZ = perspectiveDepthToViewZ(texture, cameraNear, cameraFar);
                node = viewZToOrthographicDepth(viewZ, cameraNear, cameraFar);
                break;
            case ViewportDepthNode.DEPTH_PIXEL:
                if (this.valueNode != null) {
                    node = depthPixelBase().assign(this.valueNode);
                }
                break;
        }
        return node;
    }

    public static function viewZToOrthographicDepth(viewZ: Node, near: Node, far: Node) -> Node {
        return (viewZ.add(near)).div(near.sub(far));
    }

    public static function orthographicDepthToViewZ(depth: Node, near: Node, far: Node) -> Node {
        return (near.sub(far)).mul(depth).sub(near);
    }

    public static function viewZToPerspectiveDepth(viewZ: Node, near: Node, far: Node) -> Node {
        return (near.add(viewZ)).mul(far).div((far.sub(near)).mul(viewZ));
    }

    public static function perspectiveDepthToViewZ(depth: Node, near: Node, far: Node) -> Node {
        return (near.mul(far)).div((far.sub(near)).mul(depth).sub(far));
    }
}

enum ViewportDepthNode.Scope {
    DEPTH,
    DEPTH_TEXTURE,
    DEPTH_PIXEL
}

var depthPixelBase = nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

var depth = nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH);
var depthTexture = nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE);
var depthPixel = nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

depthPixel.assign = function(value) -> Node {
    return depthPixelBase(value);
}

addNodeClass('ViewportDepthNode', ViewportDepthNode);

export { ViewportDepthNode, depth, depthTexture, depthPixel };