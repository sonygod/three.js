package three.test.unit.src.core;

import haxe.unit.TestCase;
import three.core.UniformsGroup;
import three.core.EventDispatcher;

class UniformsGroupTests extends TestCase
{
    public function new() { super(); }

    public function testExtending():Void
    {
        var object:UniformsGroup = new UniformsGroup();
        assertTrue(object instanceof EventDispatcher, 'UniformsGroup extends from EventDispatcher');
    }

    public function testInstancing():Void
    {
        var object:UniformsGroup = new UniformsGroup();
        assertNotNull(object, 'Can instantiate a UniformsGroup.');
    }

    public function todo_id():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_name():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_usage():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_uniforms():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsUniformsGroup():Void
    {
        var object:UniformsGroup = new UniformsGroup();
        assertTrue(object.isUniformsGroup, 'UniformsGroup.isUniformsGroup should be true');
    }

    public function todo_add():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_remove():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_setName():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_setUsage():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testDispose():Void
    {
        var object:UniformsGroup = new UniformsGroup();
        object.dispose();
    }

    public function todo_copy():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todo_clone():Void
    {
        assertTrue(false, "everything's gonna be alright");
    }
}