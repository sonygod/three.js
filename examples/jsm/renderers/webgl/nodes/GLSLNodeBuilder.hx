import MathNode from '../../../nodes/Nodes.hx';
import GLSLNodeParser from '../../../nodes/GLSLNodeParser';
import NodeBuilder from '../../../nodes/NodeBuilder';
import NodeUniformBuffer from '../../common/nodes/NodeUniformBuffer';
import NodeUniformsGroup from '../../common/nodes/NodeUniformsGroup';
import NodeSampledTexture from '../../common/nodes/NodeSampledTexture';
import NodeSampledCubeTexture from '../../common/nodes/NodeSampledCubeTexture';
import RedFormat from 'three/src/renderers/webgl/textures/RedFormat';
import RGFormat from 'three/src/renderers/webgl/textures/RGFormat';
import IntType from 'three/src/renderers/webgl/types/IntType';
import DataTexture from 'three/src/renderers/webgl/textures/DataTexture';
import RGBFormat from 'three/src/renderers/webgl/textures/RGBFormat';
import RGBAFormat from 'three/src/renderers/webgl/textures/RGBAFormat';
import FloatType from 'three/src/renderers/webgl/types/FloatType';

class GLSLNodeBuilder extends NodeBuilder {
	public var glslMethods:Dynamic;
	public var precisionLib:Dynamic;
	public var supports:Dynamic;
	public var defaultPrecisions:String;

	public function new(object:Dynamic, renderer:Dynamic, scene:Dynamic = null) {
		super(object, renderer, new GLSLNodeParser(), scene);
		this.uniformGroups = {};
		this.transforms = [];
		this.glslMethods = {
			[MathNode.ATAN2]:'atan',
			textureDimensions:'textureSize',
			equals:'equal'
		};
		this.precisionLib = {
			low:'lowp',
			medium:'mediump',
			high:'highp'
		};
		this.supports = {
			instance:true,
			swizzleAssign:true
		};
		this.defaultPrecisions = "precision highp float;\nprecision highp int;\nprecision mediump sampler2DArray;\nprecision lowp sampler2DShadow;";
	}

	// ... (other methods from the JavaScript code)
}