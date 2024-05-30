import TempNode from '../core/TempNode.hx';
import { nodeObject, addNodeElement, $tslFn, $float, $vec2, $vec3, $vec4 } from '../shadernode/ShaderNode.hx';
import { loop } from '../utils/LoopNode.hx';
import { uniform } from '../core/UniformNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { threshold } from './ColorAdjustmentNode.hx';
import { uv } from '../accessors/UVNode.hx';
import { texturePass } from './PassNode.hx';
import { Vector2, RenderTarget } from 'three';
import QuadMesh from '../../objects/QuadMesh.hx';

var quadMesh = new QuadMesh();

class AnamorphicNode extends TempNode {
    constructor(textureNode, tresholdNode, scaleNode, samples) {
        super('vec4');
        this.textureNode = textureNode;
        this.tresholdNode = tresholdNode;
        this.scaleNode = scaleNode;
        this.colorNode = $vec3(0.1, 0.0, 1.0);
        this.samples = samples;
        this.resolution = new Vector2(1, 1);
        this._renderTarget = new RenderTarget();
        this._renderTarget.texture.name = 'anamorphic';
        this._invSize = uniform(new Vector2());
        this._textureNode = texturePass(this, this._renderTarget.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public getTextureNode() {
        return this._textureNode;
    }

    public setSize(width, height) {
        this._invSize.value.set(1 / width, 1 / height);
        width = Math.max(Math.round(width * this.resolution.x), 1);
        height = Math.max(Math.round(height * this.resolution.y), 1);
        this._renderTarget.setSize(width, height);
    }

    public updateBefore(frame) {
        const renderer = frame.renderer;
        const textureNode = this.textureNode;
        const map = textureNode.value;
        this._renderTarget.texture.type = map.type;
        const currentRenderTarget = renderer.getRenderTarget();
        const currentTexture = textureNode.value;
        quadMesh.material = this._material;
        this.setSize(map.image.width, map.image.height);
        renderer.setRenderTarget(this._renderTarget);
        quadMesh.render(renderer);
        renderer.setRenderTarget(currentRenderTarget);
        textureNode.value = currentTexture;
    }

    public setup(builder) {
        const textureNode = this.textureNode;
        if (textureNode.isTextureNode !== true) {
            console.error('AnamorphNode requires a TextureNode.');
            return $vec4();
        }
        const uvNode = textureNode.uvNode ?? uv();
        const sampleTexture = (uv) => textureNode.cache().context({getUV: () => uv, forceUVContext: true});
        const anamorph = $tslFn(() => {
            const samples = this.samples;
            const halfSamples = Math.floor(samples / 2);
            const total = $vec3(0).toVar();
            loop({start: -halfSamples, end: halfSamples}, ({i}) => {
                const softness = $float(i).abs().div(halfSamples).oneMinus();
                const uv = $vec2(uvNode.x.add(this._invSize.x.mul(i).mul(this.scaleNode)), uvNode.y);
                const color = sampleTexture(uv);
                const pass = threshold(color, this.tresholdNode).mul(softness);
                total.addAssign(pass);
            });
            return total.mul(this.colorNode);
        });
        const material = this._material ?? (this._material = builder.createNodeMaterial());
        material.fragmentNode = anamorph();
        const properties = builder.getNodeProperties(this);
        properties.textureNode = textureNode;
        return this._textureNode;
    }
}

function anamorphic(node, threshold = 0.9, scale = 3, samples = 32) {
    return nodeObject(new AnamorphicNode(nodeObject(node), nodeObject(threshold), nodeObject(scale), samples));
}

addNodeElement('anamorphic', anamorphic);

export default AnamorphicNode;