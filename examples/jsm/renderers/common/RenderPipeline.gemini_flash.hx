import Pipeline from "./Pipeline";

class RenderPipeline extends Pipeline {
  public var vertexProgram:Dynamic;
  public var fragmentProgram:Dynamic;

  public function new(cacheKey:String, vertexProgram:Dynamic, fragmentProgram:Dynamic) {
    super(cacheKey);
    this.vertexProgram = vertexProgram;
    this.fragmentProgram = fragmentProgram;
  }
}

class RenderPipeline {
  public static function main():Void {
    trace("Hello, world!");
  }
}