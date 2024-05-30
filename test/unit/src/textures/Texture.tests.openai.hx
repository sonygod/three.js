import haxe.unit.TestRunner;
import three.textures.Texture;
import three.core.EventDispatcher;

class TextureTests {
    public static function main() {
        var runner = new TestRunner();
        runner.add(new TextureTests());
        runner.run();
    }

    public function new() {}

    public function testInheritance() {
        var object = new Texture();
        assertTrue(object instanceof EventDispatcher, 'Texture extends from EventDispatcher');
    }

    public function testInstancing() {
        var object = new Texture();
        assertNotNull(object, 'Can instantiate a Texture.');
    }

    // PROPERTIES
    public function todo_image() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_id() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_uuid() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_name() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_source() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_mipmaps() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_mapping() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_wrapS() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_wrapT() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_magFilter() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_minFilter() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_anisotropy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_format() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_internalFormat() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_type() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_offset() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_repeat() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_center() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_rotation() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_matrixAutoUpdate() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_matrix() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_generateMipmaps() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_premultiplyAlpha() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_flipY() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_unpackAlignment() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_colorSpace() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_userData() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_version() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_onUpdate() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_needsPMREMUpdate() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsTexture() {
        var object = new Texture();
        assertTrue(object.isTexture, 'Texture.isTexture should be true');
    }

    public function todo_updateMatrix() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_clone() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_copy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todo_toJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose() {
        var object = new Texture();
        object.dispose();
    }

    public function todo_transformUv() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}