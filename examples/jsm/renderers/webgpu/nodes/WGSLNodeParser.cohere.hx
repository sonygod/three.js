class WGSLNodeParser {
	public function parseFunction(source:String):WGSLNodeFunction {
		return new WGSLNodeFunction(source);
	}
}