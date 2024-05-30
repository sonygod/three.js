import TextureNode from '../accessors/TextureNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';
import { viewportTopLeft } from './ViewportNode.hx';

class ViewportTextureNode extends TextureNode {
    public generateMipmaps:Bool;
    public updateBeforeType:NodeUpdateType;
    public isOutputTextureNode:Bool;
    public var _size:Vector2;

    public function new(uvNode:Dynamic = viewportTopLeft, levelNode:Dynamic = null, framebufferTexture:Dynamic = null) {
        super(framebufferTexture, uvNode, levelNode);
        this.generateMipmaps = false;
        this.isOutputTextureNode = true;
        this.updateBeforeType = NodeUpdateType.FRAME;
        this._size = new Vector2();
    }

    public function updateBefore(frame:Dynamic) {
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

    public function clone():ViewportTextureNode {
        var viewportTextureNode = new ViewportTextureNode(this.uvNode, this.levelNode, this.value);
        viewportTextureNode.generateMipmaps = this.generateMipmaps;
        return viewportTextureNode;
    }
}

@:expose(2)
static function viewportTexture(uvNode:Dynamic = viewportTopLeft, levelNode:Dynamic = null) -> ViewportTextureNode {
    return new ViewportTextureNode(uvNode, levelNode);
}

@:expose(2)
static function viewportMipTexture(uvNode:Dynamic = viewportTopLeft, levelNode:Dynamic = null) -> ViewportTextureNode {
    var node = new ViewportTextureNode(uvNode, levelNode, null);
    node.generateMipmaps = true;
    return node;
}

static function __init__() {
    addNodeElement('viewportTexture', viewportTexture);
    addNodeElement('viewportMipTexture', viewportMipTexture);
    addNodeClass('ViewportTextureNode', ViewportTextureNode);
}