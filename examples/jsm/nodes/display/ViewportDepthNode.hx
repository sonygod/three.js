package three.js.examples.jvm.nodes.display;

import three.js.core.Node;
import three.shadernode.ShaderNode;

class ViewportDepthNode extends Node {

    public static inline var DEPTH:String = 'depth';
    public static inline var DEPTH_TEXTURE:String = 'depthTexture';
    public static inline var DEPTH_PIXEL:String = 'depthPixel';

    public var scope:String;
    public var valueNode:Node;

    public function new(scope:String, ?valueNode:Node) {
        super('float');
        this.scope = scope;
        this.valueNode = valueNode;
        this.isViewportDepthNode = true;
    }

    override public function generate(builder:Dynamic) {
        if (scope == DEPTH_PIXEL) {
            return builder.getFragDepth();
        }
        return super.generate(builder);
    }

    public function setup(builder:Dynamic) {
        var node:Node = null;
        switch (scope) {
            case DEPTH:
                node = viewZToOrthographicDepth(positionView.z, cameraNear, cameraFar);
            case DEPTH_TEXTURE:
                var texture:Node = valueNode != null ? valueNode : viewportDepthTexture();
                var viewZ:Float = perspectiveDepthToViewZ(texture, cameraNear, cameraFar);
                node = viewZToOrthographicDepth(viewZ, cameraNear, cameraFar);
            case DEPTH_PIXEL:
                if (valueNode != null) {
                    node = depthPixelBase().assign(valueNode);
                }
        }
        return node;
    }

    static public function viewZToOrthographicDepth(viewZ:Float, near:Float, far:Float):Float {
        return viewZ + near / (near - far);
    }

    static public function orthographicDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return near - far * depth - near;
    }

    static public function viewZToPerspectiveDepth(viewZ:Float, near:Float, far:Float):Float {
        return near + viewZ * far / (far - near * viewZ);
    }

    static public function perspectiveDepthToViewZ(depth:Float, near:Float, far:Float):Float {
        return near * far / (far - near * depth - far);
    }
}

var depthPixelBase:Node = nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

var depth:Node = nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH);
var depthTexture:Node = nodeProxy(ViewportDepthNode, ViewportDepthNode.DEPTH_TEXTURE);
var depthPixel:Node = nodeImmutable(ViewportDepthNode, ViewportDepthNode.DEPTH_PIXEL);

depthPixel.assign = function(value:Node) {
    depthPixelBase(value);
}

addNodeClass('ViewportDepthNode', ViewportDepthNode);