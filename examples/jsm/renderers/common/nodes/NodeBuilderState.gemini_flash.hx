class NodeBuilderState {

	public var vertexShader:Dynamic;
	public var fragmentShader:Dynamic;
	public var computeShader:Dynamic;
	public var transforms:Array<Dynamic>;
	public var nodeAttributes:Dynamic;
	public var bindings:Array<Dynamic>;
	public var updateNodes:Dynamic;
	public var updateBeforeNodes:Dynamic;
	public var usedTimes:Int = 0;

	public function new(vertexShader:Dynamic, fragmentShader:Dynamic, computeShader:Dynamic, nodeAttributes:Dynamic, bindings:Array<Dynamic>, updateNodes:Dynamic, updateBeforeNodes:Dynamic, transforms:Array<Dynamic> = []) {
		this.vertexShader = vertexShader;
		this.fragmentShader = fragmentShader;
		this.computeShader = computeShader;
		this.transforms = transforms;
		this.nodeAttributes = nodeAttributes;
		this.bindings = bindings;
		this.updateNodes = updateNodes;
		this.updateBeforeNodes = updateBeforeNodes;
	}

	public function createBindings():Array<Dynamic> {
		var bindingsArray:Array<Dynamic> = [];
		for (instanceBinding in bindings) {
			var binding = instanceBinding;
			if (!instanceBinding.shared) {
				binding = instanceBinding.clone();
			}
			bindingsArray.push(binding);
		}
		return bindingsArray;
	}

}