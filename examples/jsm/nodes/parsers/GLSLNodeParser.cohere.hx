class GLSLNodeParser extends NodeParser {
	public function parseFunction(source:String):GLSLNodeFunction {
		return new GLSLNodeFunction(source);
	}
}