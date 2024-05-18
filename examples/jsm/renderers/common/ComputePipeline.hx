package three.js.examples.jm.renderers.common;

import three.js.examples.jm.renderers.common.Pipeline;

class ComputePipeline extends Pipeline {

    public var computeProgram:Dynamic;

    public function new(cacheKey:String, computeProgram:Dynamic) {
        super(cacheKey);
        this.computeProgram = computeProgram;
        this.isComputePipeline = true;
    }

}