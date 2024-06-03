import jsm.nodes.accessors.TextureNode;
import jsm.nodes.core.constants.NodeUpdateType;
import jsm.nodes.core.Node;
import jsm.nodes.shadernode.ShaderNode;
import jsm.nodes.display.ViewportNode;
import three.Vector2;
import three.FramebufferTexture;
import three.LinearMipmapLinearFilter;

class ViewportTextureNode extends TextureNode {

    private var _size:Vector2;

    public function new(uvNode:ViewportNode = ViewportNode.viewportTopLeft, levelNode:Node = null, framebufferTexture:FramebufferTexture = null) {

        if (framebufferTexture == null) {

            framebufferTexture = new FramebufferTexture();
            framebufferTexture.minFilter = LinearMipmapLinearFilter;

        }

        super(framebufferTexture, uvNode, levelNode);

        this.generateMipmaps = false;

        this.isOutputTextureNode = true;

        this.updateBeforeType = NodeUpdateType.FRAME;

        this._size = new Vector2();

    }

    override public function updateBefore(frame:Frame) {

        var renderer = frame.renderer;
        renderer.getDrawingBufferSize(this._size);

        var framebufferTexture = this.value;

        if (framebufferTexture.image.width != this._size.width || framebufferTexture.image.height != this._size.height) {

            framebufferTexture.image.width = this._size.width;
            framebufferTexture.image.height = this._size.height;
            framebufferTexture.needsUpdate = true;

        }

        var currentGenerateMipmaps = framebufferTexture.generateMipmaps;
        framebufferTexture.generateMipmaps = this.generateMipmaps;

        renderer.copyFramebufferToTexture(framebufferTexture);

        framebufferTexture.generateMipmaps = currentGenerateMipmaps;

    }

    override public function clone():ViewportTextureNode {

        var viewportTextureNode = new this.constructor(this.uvNode, this.levelNode, this.value);
        viewportTextureNode.generateMipmaps = this.generateMipmaps;

        return viewportTextureNode;

    }

}

var viewportTexture = ShaderNode.nodeProxy(ViewportTextureNode);
var viewportMipTexture = ShaderNode.nodeProxy(ViewportTextureNode, null, null, {generateMipmaps: true});

ShaderNode.addNodeElement('viewportTexture', viewportTexture);
ShaderNode.addNodeElement('viewportMipTexture', viewportMipTexture);

Node.addNodeClass('ViewportTextureNode', ViewportTextureNode);