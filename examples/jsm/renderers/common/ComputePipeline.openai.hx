package three.js.examples.jsm.renderers.common;

import Pipeline;

class ComputePipeline extends Pipeline {
    public var computeProgram:Dynamic;
    public var isComputePipeline:Bool;

    public function new(cacheKey:String, computeProgram:Dynamic) {
        super(cacheKey);
        this.computeProgram = computeProgram;
        this.isComputePipeline = true;
    }
}