import NoColorSpace from 'three.NoColorSpace';
import FloatType from 'three.FloatType';
import NodeUniformsGroup from 'three.renderers.common.nodes.NodeUniformsGroup';
import NodeSampler from 'three.renderers.common.nodes.NodeSampler';
import NodeSampledTexture from 'three.renderers.common.nodes.NodeSampledTexture';
import NodeSampledCubeTexture from 'three.renderers.common.nodes.NodeSampledCubeTexture';
import NodeUniformBuffer from 'three.renderers.common.nodes.NodeUniformBuffer';
import NodeStorageBuffer from 'three.renderers.common.nodes.NodeStorageBuffer';
import NodeBuilder from 'three.nodes.NodeBuilder';
import CodeNode from 'three.nodes.CodeNode';
import getFormat from 'three.renderers.webgpu.utils.WebGPUTextureUtils.getFormat';
import WGSLNodeParser from 'three.renderers.webgpu.nodes.WGSLNodeParser';

class GPUShaderStage {
    static var VERTEX:Int = 1;
    static var FRAGMENT:Int = 2;
    static var COMPUTE:Int = 4;
}

class WGSLNodeBuilder extends NodeBuilder {
    public var uniformGroups:Dynamic;
    public var builtins:Dynamic;

    public function new(object:Dynamic, renderer:Dynamic, scene:Dynamic = null) {
        super(object, renderer, new WGSLNodeParser(), scene);
        this.uniformGroups = {};
        this.builtins = {};
    }

    public function needsColorSpaceToLinear(texture:Dynamic):Bool {
        return texture.isVideoTexture == true && texture.colorSpace != NoColorSpace;
    }

    private function _generateTextureSample(texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage):String {
        if (shaderStage == 'fragment') {
            if (depthSnippet) {
                return `textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})`;
            } else {
                return `textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})`;
            }
        } else {
            return this.generateTextureLod(texture, textureProperty, uvSnippet);
        }
    }

    private function _generateVideoSample(textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage):String {
        if (shaderStage == 'fragment') {
            return `textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))`;
        } else {
            trace('WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.');
            return '';
        }
    }

    private function _generateTextureSampleLevel(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage):String {
        if (shaderStage == 'fragment' && this.isUnfilterable(texture) == false) {
            return `textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})`;
        } else {
            return this.generateTextureLod(texture, textureProperty, uvSnippet, levelSnippet);
        }
    }

    public function generateTextureLod(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String = '0'):String {
        this._include('repeatWrapping');
        const dimension = `textureDimensions(${textureProperty}, 0)`;
        return `textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))`;
    }

    // ... other methods ...
}