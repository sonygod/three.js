import Pipeline from './Pipeline.js';

class RenderPipeline extends Pipeline {

	public var vertexProgram:Dynamic;
	public var fragmentProgram:Dynamic;

	public function new(cacheKey:String, vertexProgram:Dynamic, fragmentProgram:Dynamic) {

		super(cacheKey);

		this.vertexProgram = vertexProgram;
		this.fragmentProgram = fragmentProgram;

	}

}

export default RenderPipeline;