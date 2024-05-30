package three.materials;

import haxe.unit.TestCase;
import three.materials.Material;
import three.core.EventDispatcher;

class MaterialTest extends TestCase {
    function testExtending() {
        var object:Material = new Material();
        assertTrue(object instanceof EventDispatcher, 'Material extends from EventDispatcher');
    }

    function testInstancing() {
        var object:Material = new Material();
        assertTrue(object != null, 'Can instantiate a Material.');
    }

    function testType() {
        var object:Material = new Material();
        assertEquals(object.type, 'Material', 'Material.type should be Material');
    }

    function testTodoProperties() {
        todo('id');
        todo('uuid');
        todo('name');
        todo('blending');
        todo('side');
        todo('vertexColors');
        todo('opacity');
        todo('transparent');
        todo('blendSrc');
        todo('blendDst');
        todo('blendEquation');
        todo('blendSrcAlpha');
        todo('blendDstAlpha');
        todo('blendEquationAlpha');
        todo('depthFunc');
        todo('depthTest');
        todo('depthWrite');
        todo('stencilWriteMask');
        todo('stencilFunc');
        todo('stencilRef');
        todo('stencilFuncMask');
        todo('stencilFail');
        todo('stencilZFail');
        todo('stencilZPass');
        todo('stencilWrite');
        todo('clippingPlanes');
        todo('clipIntersection');
        todo('clipShadows');
        todo('shadowSide');
        todo('colorWrite');
        todo('precision');
        todo('polygonOffset');
        todo('polygonOffsetFactor');
        todo('polygonOffsetUnits');
        todo('dithering');
        todo('alphaToCoverage');
        todo('premultipliedAlpha');
        todo('forceSinglePass');
        todo('visible');
        todo('toneMapped');
        todo('userData');
        todo('alphaTest');
        todo('needsUpdate');
    }

    function testIsMaterial() {
        var object:Material = new Material();
        assertTrue(object.isMaterial, 'Material.isMaterial should be true');
    }

    function test TodoMethods() {
        todo('onBuild');
        todo('onBeforeRender');
        todo('onBeforeCompile');
        todo('customProgramCacheKey');
        todo('setValues');
        todo('toJSON');
        todo('clone');
        todo('copy');
    }

    function testDispose() {
        var object:Material = new Material();
        object.dispose();
    }
}