package three.js.examples.jsm.nodes.core;

class LightingModel {
    public function new() {}

    public function start(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

    public function finish(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

    public function direct(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

    public function indirectDiffuse(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

    public function indirectSpecular(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}

    public function ambientOcclusion(input:Dynamic, stack:Dynamic, builder:Dynamic):Void {}
}

// Note: In Haxe, we don't need to use the `export` keyword to make the class visible.
// The class is already public and can be accessed from other parts of the code.