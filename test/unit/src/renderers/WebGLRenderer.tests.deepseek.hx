package three.test.unit.src.renderers;

import three.src.renderers.WebGLRenderer;
import js.Lib;

class WebGLRendererTests {
    static function main() {
        var renderer = new WebGLRenderer();
        Lib.assert(renderer != null, 'Can instantiate a WebGLRenderer.');

        // TODO: Add other tests here
    }
}