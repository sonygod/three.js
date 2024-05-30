import Pipeline from './Pipeline.js';

class RenderPipeline extends Pipeline {

	public function new(cacheKey:String, vertexProgram:Dynamic, fragmentProgram:Dynamic) {
		super(cacheKey);
		this.vertexProgram = vertexProgram;
		this.fragmentProgram = fragmentProgram;
	}

	public var vertexProgram:Dynamic;
	public var fragmentProgram:Dynamic;

}

@:native("default")
class RenderPipelineDefault extends RenderPipeline {}