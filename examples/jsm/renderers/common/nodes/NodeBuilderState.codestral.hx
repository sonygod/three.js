class NodeBuilderState {

    public var vertexShader: String;
    public var fragmentShader: String;
    public var computeShader: String;
    public var transforms: Array<Dynamic>;

    public var nodeAttributes: Dynamic;
    public var bindings: Array<Dynamic>;

    public var updateNodes: Dynamic;
    public var updateBeforeNodes: Dynamic;

    public var usedTimes: Int;

    public function new(vertexShader: String, fragmentShader: String, computeShader: String, nodeAttributes: Dynamic, bindings: Array<Dynamic>, updateNodes: Dynamic, updateBeforeNodes: Dynamic, transforms: Array<Dynamic> = []) {

        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
        this.computeShader = computeShader;
        this.transforms = transforms;

        this.nodeAttributes = nodeAttributes;
        this.bindings = bindings;

        this.updateNodes = updateNodes;
        this.updateBeforeNodes = updateBeforeNodes;

        this.usedTimes = 0;
    }

    public function createBindings(): Array<Dynamic> {

        var bindingsArray: Array<Dynamic> = [];

        for (instanceBinding in this.bindings) {

            var binding: Dynamic = instanceBinding;

            if (instanceBinding.shared != true) {

                binding = instanceBinding.clone();

            }

            bindingsArray.push(binding);

        }

        return bindingsArray;

    }

}