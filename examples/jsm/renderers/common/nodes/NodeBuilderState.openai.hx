package three.js.examples.jsm.renderers.common.nodes;

class NodeBuilderState {
    public var vertexShader:String;
    public var fragmentShader:String;
    public var computeShader:String;
    public var transforms:Array Dynamic;
    public var nodeAttributes:Dynamic;
    public var bindings:Array<Dynamic>;
    public var updateNodes:Void->Void;
    public var updateBeforeNodes:Void->Void;
    public var usedTimes:Int;

    public function new(vertexShader:String, fragmentShader:String, computeShader:String, nodeAttributes:Dynamic, bindings:Array<Dynamic>, updateNodes:Void->Void, updateBeforeNodes:Void->Void, ?transforms:Array<Dynamic>) {
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
        this.computeShader = computeShader;
        this.transforms = transforms != null ? transforms : [];

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
            if (!binding.shared) {
                binding = instanceBinding.clone();
            }
            bindingsArray.push(binding);
        }

        return bindingsArray;
    }
}