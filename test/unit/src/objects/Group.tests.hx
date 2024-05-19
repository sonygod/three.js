package three.test.unit.src.objects;

import three.objects.Group;
import three.core.Object3D;

class GroupTests {
    public function new() {}

    public function testGroup() {
        // INHERITANCE
        assertTrue(Type.typeof(new Group()) == Type.getType(Object3D), 'Group extends from Object3D');

        // INSTANCING
        var object = new Group();
        assertNotNull(object, 'Can instantiate a Group.');

        // PROPERTIES
        object = new Group();
        assertEquals(object.type, 'Group', 'Group.type should be Group');

        // PUBLIC
        object = new Group();
        assertTrue(object.isGroup, 'Group.isGroup should be true');
    }
}