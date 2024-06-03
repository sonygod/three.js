import TempNode from '../core/TempNode';
import { NodeObject, AddNodeElement, TslFn, Float, Vec2, Vec3, Vec4 } from '../shadernode/ShaderNode';
import { Loop } from '../utils/LoopNode';
import { Uniform } from '../core/UniformNode';
import { NodeUpdateType } from '../core/constants';
import { Threshold } from './ColorAdjustmentNode';
import { UV } from '../accessors/UVNode';
import { TexturePass } from './PassNode';
import { Vector2, RenderTarget } from 'three';
import QuadMesh from '../../objects/QuadMesh';

var quadMesh = new QuadMesh();

class AnamorphicNode extends TempNode {

    public var textureNode: NodeObject;
    public var tresholdNode: NodeObject;
    public var scaleNode: NodeObject;
    public var colorNode: Vec3 = Vec3.fromArray([0.1, 0.0, 1.0]);
    public var samples: Int;
    public var resolution: Vector2 = new Vector2(1, 1);
    private var _renderTarget: RenderTarget = new RenderTarget();
    private var _invSize: NodeObject = Uniform(new Vector2());
    private var _textureNode: NodeObject;

    public function new(textureNode: NodeObject, tresholdNode: NodeObject, scaleNode: NodeObject, samples: Int) {
        super('vec4');

        this.textureNode = textureNode;
        this.tresholdNode = tresholdNode;
        this.scaleNode = scaleNode;
        this.samples = samples;

        this._renderTarget.texture.name = 'anamorphic';
        this._textureNode = TexturePass(this, this._renderTarget.texture);
        this.updateBeforeType = NodeUpdateType.RENDER;
    }

    public function getTextureNode(): NodeObject {
        return this._textureNode;
    }

    public function setSize(width: Float, height: Float): Void {
        this._invSize.value.set(1 / width, 1 / height);
        width = Math.max(Math.round(width * this.resolution.x), 1);
        height = Math.max(Math.round(height * this.resolution.y), 1);
        this._renderTarget.setSize(width, height);
    }

    public function updateBefore(frame: Frame): Void {
        const map = this.textureNode.value;
        this._renderTarget.texture.type = map.type;
        const currentRenderTarget = frame.renderer.getRenderTarget();
        const currentTexture = this.textureNode.value;

        quadMesh.material = this._material;
        this.setSize(map.image.width, map.image.height);

        // render
        frame.renderer.setRenderTarget(this._renderTarget);
        quadMesh.render(frame.renderer);

        // restore
        frame.renderer.setRenderTarget(currentRenderTarget);
        this.textureNode.value = currentTexture;
    }

    public function setup(builder: Builder): NodeObject {
        if (this.textureNode.isTextureNode !== true) {
            trace('AnamorphNode requires a TextureNode.');
            return Vec4();
        }

        const uvNode = this.textureNode.uvNode || UV();
        const sampleTexture = (uv: Vec2) => this.textureNode.cache().context({ getUV: () => uv, forceUVContext: true });

        const anamorph = TslFn(() => {
            const halfSamples = Math.floor(this.samples / 2);
            var total = Vec3.fromArray([0]).toVar();

            Loop({ start: -halfSamples, end: halfSamples }, ({ i }) => {
                const softness = Float(Math.abs(i)).div(halfSamples).oneMinus();
                const uv = Vec2(uvNode.x.add(this._invSize.x.mul(i).mul(this.scaleNode)), uvNode.y);
                const color = sampleTexture(uv);
                const pass = Threshold(color, this.tresholdNode).mul(softness);
                total.addAssign(pass);
            });

            return total.mul(this.colorNode);
        });

        const material = this._material || (this._material = builder.createNodeMaterial());
        material.fragmentNode = anamorph();

        const properties = builder.getNodeProperties(this);
        properties.textureNode = this.textureNode;

        return this._textureNode;
    }
}

export function anamorphic(node: NodeObject, threshold: Float = 0.9, scale: Float = 3, samples: Int = 32): NodeObject {
    return NodeObject(new AnamorphicNode(NodeObject(node), NodeObject(threshold), NodeObject(scale), samples));
}

AddNodeElement('anamorphic', anamorphic);

export default AnamorphicNode;