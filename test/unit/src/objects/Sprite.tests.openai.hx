package three.test.unit.objects;

import three.core.Object3D;
import three.objects.Sprite;

class SpriteTests {
    public function new() {}

    public static function main() {
        Hut.test("Objects", suite => {
            suite.test("Sprite", suite => {
                // INHERITANCE
                suite.test("Extending", Assert => {
                    var sprite = new Sprite();
                    Assert.isTrue(sprite instanceof Object3D, 'Sprite extends from Object3D');
                });

                // INSTANCING
                suite.test("Instancing", Assert => {
                    var object = new Sprite();
                    Assert.notNull(object, 'Can instantiate a Sprite.');
                });

                // PROPERTIES
                suite.test("type", Assert => {
                    var object = new Sprite();
                    Assert.areEqual(object.type, 'Sprite', 'Sprite.type should be Sprite');
                });

                // TODO: Implement these tests
                suite.test("geometry", Assert => {
                    Assert.fail("todo: geometry");
                });

                suite.test("material", Assert => {
                    Assert.fail("todo: material");
                });

                suite.test("center", Assert => {
                    Assert.fail("todo: center");
                });

                // PUBLIC
                suite.test("isSprite", Assert => {
                    var object = new Sprite();
                    Assert.isTrue(object.isSprite, 'Sprite.isSprite should be true');
                });

                // TODO: Implement these tests
                suite.test("raycast", Assert => {
                    Assert.fail("todo: raycast");
                });

                suite.test("copy", Assert => {
                    Assert.fail("todo: copy");
                });
            });
        });
    }
}