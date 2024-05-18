package three.js.examples.jsm.nodes.display;

import three.js.accessors.TextureNode;
import three.js.core.constants.NodeUpdateType;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.nodes.display.ViewportNode;
import three.js.lib.Vector2;
import three.js.lib.FramebufferTexture;
import three.js.lib.LinearMipmapLinearFilter;

class ViewportTextureNode extends TextureNode {

    var _size:Vector2 = new Vector2();

    public function new(uvNode:Node = ViewportNode.viewportTopLeft, levelNode:Node = null, framebufferTexture:FramebufferTexture = null) {
        if (framebufferTexture == null) {
            framebufferTexture = new FramebufferTexture();
            framebufferTexture.minFilter = LinearMipmapLinearFilter;
        }
        super(framebufferTexture, uvNode, levelNode);
        this.generateMipmaps = false;
        this.isOutputTextureNode = true;
        this.updateBeforeType = NodeUpdateType.FRAME;
    }

    public function updateBefore(frame:Dynamic) {
        var renderer = frame.renderer;
        renderer.getDrawingBufferSize(_size);
        var framebufferTexture:FramebufferTexture = this.value;
        if (framebufferTexture.image.width != _size.width || framebufferTexture.image.height != _size.height) {
            framebufferTexture.image.width = _size.width;
            framebufferTexture.image.height = _size.height;
            framebufferTexture.needsUpdate = true;
        }
        var currentGenerateMipmaps = framebufferTexture.generateMipmaps;
        framebufferTexture.generateMipmaps = this.generateMipmaps;
        renderer.copyFramebufferToTexture(framebufferTexture);
        framebufferTexture.generateMipmaps = currentGenerateMipmaps;
    }

    public function clone():ViewportTextureNode {
        var viewportTextureNode:ViewportTextureNode = new ViewportTextureNode(this.uvNode, this.levelNode, this.value);
        viewportTextureNode.generateMipmaps = this.generateMipmaps;
        return viewportTextureNode;
    }
}

export var viewportTexture:Dynamic = ShaderNode.nodeProxy(ViewportTextureNode);
export var viewportMipTexture:Dynamic = ShaderNode.nodeProxy(ViewportTextureNode, null, null, { generateMipmaps: true });

ShaderNode.addNodeElement('viewportTexture', viewportTexture);
ShaderNode.addNodeElement('viewportMipTexture', viewportMipTexture);

Node.addNodeClass('ViewportTextureNode', ViewportTextureNode);