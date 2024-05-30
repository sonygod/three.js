class LightingModel {

	public function start(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

	public function finish(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

	public function direct(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

	public function indirectDiffuse(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

	public function indirectSpecular(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

	public function ambientOcclusion(input:Dynamic, stack:Dynamic, builder:Dynamic) { }

}

export default LightingModel;


Please note that the `Dynamic` type is used for the input, stack, and builder parameters since the specific types are not provided in the JavaScript code. You may need to replace `Dynamic` with the appropriate types based on your use case.

Also, Haxe does not have a direct equivalent to JavaScript's default export. Instead, you can use the `export` keyword before the class definition to make it accessible from other modules. If you want to use the class as a default export, you can do so by importing it with an alias in the consuming module:

import LightingModel.LightingModel as DefaultLightingModel;