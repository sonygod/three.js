import Pipeline from "./Pipeline";

class ComputePipeline extends Pipeline {

	public var computeProgram:Dynamic;
	public var isComputePipeline:Bool = true;

	public function new(cacheKey:String, computeProgram:Dynamic) {
		super(cacheKey);
		this.computeProgram = computeProgram;
	}

}

class ComputePipeline {
	public static var default:ComputePipeline = new ComputePipeline();
}