import Pipeline from './Pipeline.hx';

class ComputePipeline extends Pipeline {

    public var computeProgram;

    public var isComputePipeline:Bool = true;

    public function new(cacheKey:String, computeProgram:Dynamic) {
        super(cacheKey);
        this.computeProgram = computeProgram;
    }

}

export default ComputePipeline;


Please note that the `Dynamic` type is used for the `computeProgram` parameter in the constructor as the type is not specified in the JavaScript code. You may need to replace it with the appropriate type based on your specific use case.

Also, Haxe does not have a built-in `export default` syntax like JavaScript. Instead, you can use `@:export` metadata to achieve a similar effect. However, this is not necessary if you are using a module system like hx-nodejs or haxe-js.

Here is how you can use `@:export`:


@:export
class ComputePipeline extends Pipeline {
    ...
}