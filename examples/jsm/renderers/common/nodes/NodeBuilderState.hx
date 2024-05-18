package three.js.examples.jsm.renderers.common.nodes;

class NodeBuilderState {
    public var vertexShader:Dynamic;
    public var fragmentShader:Dynamic;
    public var computeShader:Dynamic;
    public var transforms:Array<Dynamic>;
    public var nodeAttributes:Dynamic;
    public var bindings:Array<Dynamic>;
    public var updateNodes:Dynamic;
    public var updateBeforeNodes:Dynamic;
    public var usedTimes:Int;

    public function new(vertexShader:Dynamic, fragmentShader:Dynamic, computeShader:Dynamic, nodeAttributes:Dynamic, bindings:Array<Dynamic>, updateNodes:Dynamic, updateBeforeNodes:Dynamic, ?transforms:Array<Dynamic> = []) {
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

    public function createBindings():Array<Dynamic> {
        var bindingsArray:Array<Dynamic> = [];

        for (binding in this.bindings) {
            var instanceBinding:Dynamic = binding;
            if (!instanceBinding.shared) {
                instanceBinding = instanceBinding.clone();
            }
            bindingsArray.push(instanceBinding);
        }

        return bindingsArray;
    }
}