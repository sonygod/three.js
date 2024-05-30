abstract LightingModel {

	public function new() {}

	public function start(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

	public function finish(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

	public function direct(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

	public function indirectDiffuse(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

	public function indirectSpecular(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

	public function ambientOcclusion(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

}