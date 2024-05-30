package three.renderers.shaders.ShaderChunk;

class alphatest_pars_fragment {
    static public function main() {
        #if USE_ALPHATEST
            var alphaTest:Float;
        #end
    }
}


Please note that Haxe does not have a direct equivalent to JavaScript's default export, so I've created a class with a static function instead. Also, Haxe does not have a direct equivalent to JavaScript's template literals, so I've removed the template literal syntax.

The `USE_ALPHATEST` conditional compilation flag should be defined elsewhere in your Haxe code, depending on your project's structure and build process.

Finally, please note that this code assumes that the `Float` type is imported from the `haxe.lang` package. If it is not, you will need to add the following import statement at the beginning of your code:


import haxe.lang.Float;