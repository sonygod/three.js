package three.js.test.unit.src.renderers.shaders;

import three.js.renderers.shaders.ShaderLib;

class ShaderLibTests {

    public function new() {}

    public function testShaderLib() {
        #if unity_test
        HQUnit.module("Renderers", ()=>{
            HQUnit.module("Shaders", ()=>{
                HQUnit.module("ShaderLib", ()=>{
                    HQUnit.test("Instancing", ()=>{
                       HQUnit.ok(ShaderLib != null, 'ShaderLib is defined.');
                    });
                });
            });
        });
        #end
    }

}