import three.core.NoColorSpace;
import three.materials.nodes.NodeUniformsGroup;
import three.materials.nodes.NodeSampler;
import three.materials.nodes.NodeSampledTexture;
import three.materials.nodes.NodeUniformBuffer;
import three.materials.nodes.NodeStorageBuffer;
import three.nodes.NodeBuilder;
import three.nodes.CodeNode;
import three.textures.WebGPUTextureUtils;
import three.webgpu.WGSLNodeParser;

class WGSLNodeBuilder extends NodeBuilder {
	public var uniformGroups: {[key:String] : NodeUniformsGroup};
	public var builtins: {[key:String] : {name:String, property:String, type:String}};

	public function new(object:Dynamic, renderer:Dynamic, scene:Dynamic = null) {
		super(object, renderer, new WGSLNodeParser(), scene);
		this.uniformGroups = {};
		this.builtins = {};
	}

	// ... rest of the class methods
}