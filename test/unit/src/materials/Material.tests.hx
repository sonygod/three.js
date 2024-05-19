package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.Material;
import three.core.EventDispatcher;

class MaterialTest extends TestCase
{
    public function new() { super(); }

    override public function setUp():Void
    {
        // setup code here
    }

    override public function tearDown():Void
    {
        // teardown code here
    }

    public function testExtending():Void
    {
        var object:Material = new Material();
        assertTrue(object instanceof EventDispatcher, 'Material extends from EventDispatcher');
    }

    public function testInstancing():Void
    {
        var object:Material = new Material();
        assertTrue(object != null, 'Can instantiate a Material.');
    }

    public function testType():Void
    {
        var object:Material = new Material();
        assertEquals(object.type, 'Material', 'Material.type should be Material');
    }

    public function testDispose():Void
    {
        var object:Material = new Material();
        object.dispose();
    }

    // todo: implement tests for other properties and methods
}