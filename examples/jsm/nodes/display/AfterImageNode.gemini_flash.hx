import TempNode from "../core/TempNode";
import {nodeObject, addNodeElement, tslFn, float, vec4} from "../shadernode/ShaderNode";
import {NodeUpdateType} from "../core/constants";
import {uv} from "../accessors/UVNode";
import {texture} from "../accessors/TextureNode";
import {texturePass} from "./PassNode";
import {uniform} from "../core/UniformNode";
import {RenderTarget} from "three";
import {sign, max} from "../math/MathNode";
import QuadMesh from "../../objects/QuadMesh";

class AfterImageNode extends TempNode {

    public textureNode:TempNode;
    public textureNodeOld:TempNode;
    public damp:TempNode;
    public _compRT:RenderTarget;
    public _oldRT:RenderTarget;
    public _textureNode:TempNode;

    public function new(textureNode:TempNode, damp:Float = 0.96) {
        super(textureNode);
        this.textureNode = textureNode;
        this.textureNodeOld = texture();
        this.damp = uniform(damp);
        this._compRT = new RenderTarget();
        this._compRT.texture.name = "AfterImageNode.comp";
        this._oldRT = new RenderTarget();
        this._oldRT.texture.name = "AfterImageNode.old";
        this._textureNode = texturePass(this, this._compRT.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode():TempNode {
        return this._textureNode;
    }

    public function setSize(width:Int, height:Int):Void {
        this._compRT.setSize(width, height);
        this._oldRT.setSize(width, height);
    }

    public function updateBefore(frame:Dynamic):Void {
        var renderer = frame.renderer;
        var textureNode = this.textureNode;
        var map = textureNode.value;
        var textureType = map.type;
        this._compRT.texture.type = textureType;
        this._oldRT.texture.type = textureType;
        var currentRenderTarget = renderer.getRenderTarget();
        var currentTexture = textureNode.value;
        this.textureNodeOld.value = this._oldRT.texture;
        renderer.setRenderTarget(this._compRT);
        quadMeshComp.render(renderer);
        var temp = this._oldRT;
        this._oldRT = this._compRT;
        this._compRT = temp;
        this.setSize(map.image.width, map.image.height);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public function setup(builder:Dynamic):TempNode {
        var textureNode = this.textureNode;
        var textureNodeOld = this.textureNodeOld;
        if (!textureNode.isTextureNode) {
            console.error("AfterImageNode requires a TextureNode.");
            return vec4();
        }
        var uvNode = textureNode.uvNode || uv();
        textureNodeOld.uvNode = uvNode;
        var sampleTexture = function(uv:TempNode) {
            return textureNode.cache().context({getUV: function() {
                return uv;
            }, forceUVContext: true});
        };
        var when_gt = tslFn(function([x_immutable, y_immutable]) {
            var y = float(y_immutable).toVar();
            var x = vec4(x_immutable).toVar();
            return max(sign(x.sub(y)), 0.0);
        });
        var afterImg = tslFn(function() {
            var texelOld = vec4(textureNodeOld);
            var texelNew = vec4(sampleTexture(uvNode));
            texelOld.mulAssign(this.damp.mul(when_gt(texelOld, 0.1)));
            return max(texelNew, texelOld);
        });
        var materialComposed = this._materialComposed || (this._materialComposed = builder.createNodeMaterial());
        materialComposed.fragmentNode = afterImg();
        quadMeshComp.material = materialComposed;
        var properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return this._textureNode;
    }

}

var quadMeshComp = new QuadMesh();

export function afterImage(node:TempNode, damp:Float):TempNode {
    return nodeObject(new AfterImageNode(nodeObject(node), damp));
}

addNodeElement("afterImage", afterImage);

export default AfterImageNode;