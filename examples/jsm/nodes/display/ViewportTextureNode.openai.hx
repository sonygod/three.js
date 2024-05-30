package three.js.examples.jms.nodes.display;

import three.js.accessors.TextureNode;
import three.js.core.Constants;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.display.ViewportNode;
import three.js.Three;

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
        this.updateBeforeType = Constants.NodeUpdateType.FRAME;
    }

    public function updateBefore(frame:Dynamic) {
        var renderer:Dynamic = frame.renderer;
        renderer.getDrawingBufferSize(_size);
        var framebufferTexture:FramebufferTexture = this.value;
        if (framebufferTexture.image.width != _size.width || framebufferTexture.image.height != _size.height) {
            framebufferTexture.image.width = _size.width;
            framebufferTexture.image.height = _size.height;
            framebufferTexture.needsUpdate = true;
        }
        var currentGenerateMipmaps:Bool = framebufferTexture.generateMipmaps;
        framebufferTexture.generateMipmaps = this.generateMipmaps;
        renderer.copyFramebufferToTexture(framebufferTexture);
        framebufferTexture.generateMipmaps = currentGenerateMipmaps;
    }

    public function clone():Node {
        var viewportTextureNode = new ViewportTextureNode(this.uvNode, this.levelNode, this.value);
        viewportTextureNode.generateMipmaps = this.generateMipmaps;
        return viewportTextureNode;
    }

}

// exports
var viewportTexture:Dynamic = nodeProxy(ViewportTextureNode);
var viewportMipTexture:Dynamic = nodeProxy(ViewportTextureNode, null, null, { generateMipmaps: true });

addNodeElement('viewportTexture', viewportTexture);
addNodeElement('viewportMipTexture', viewportMipTexture);

addNodeClass('ViewportTextureNode', ViewportTextureNode);