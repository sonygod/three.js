class ComputePipeline extends Pipeline {
	public var computeProgram:ComputeProgram;
	public var isComputePipeline:Bool;

	public function new(cacheKey:String, computeProgram:ComputeProgram) {
		super(cacheKey);
		this.computeProgram = computeProgram;
		this.isComputePipeline = true;
	}
}