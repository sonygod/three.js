package three.loaders.tests;

import haxe.unit.TestCase;
import three.loaders.MaterialLoader;
import three.loaders.Loader;

class MaterialLoaderTests extends TestCase {

    public function new() {
        super();
    }

    public function testExtending():Void {
        var object:MaterialLoader = new MaterialLoader();
        assertTrue(Std.is(object, Loader), 'MaterialLoader extends from Loader');
    }

    public function testTextures():Void {
        var actual:Dynamic = new MaterialLoader().textures;
        var expected:Dynamic = {};
        assertEquals(actual, expected, 'MaterialLoader defines textures.');
    }

    public function testInstancing():Void {
        var object:MaterialLoader = new MaterialLoader();
        assertNotNull(object, 'Can instantiate a MaterialLoader.');
    }

    public function testLoad():Void {
        // todo
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testParse():Void {
        // todo
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testSetTextures():Void {
        // todo
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCreateMaterialFromType():Void {
        // todo
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main():Void {
        var testCase:MaterialLoaderTests = new MaterialLoaderTests();
        testCase.testExtending();
        testCase.testTextures();
        testCase.testInstancing();
        testCase.testLoad();
        testCase.testParse();
        testCase.setTextures();
        testCase.testCreateMaterialFromType();
    }
}