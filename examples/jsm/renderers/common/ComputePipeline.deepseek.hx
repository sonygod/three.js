import Pipeline from './Pipeline.hx';

class ComputePipeline extends Pipeline {

	public function new(cacheKey:String, computeProgram:Dynamic) {

		super(cacheKey);

		this.computeProgram = computeProgram;

		this.isComputePipeline = true;

	}

	public var computeProgram:Dynamic;

	public var isComputePipeline:Bool;

}

typedef ComputePipelineClass = {

	new(cacheKey:String, computeProgram:Dynamic):ComputePipeline;

}

var ComputePipeline:ComputePipelineClass = new ComputePipeline();