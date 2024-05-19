package three.test.unit.src.animation;

import haxe.unit.TestCase;
import three.animation.PropertyBinding;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;

class PropertyBindingTest extends TestCase {

    public function new() {
        super();

        testInstancing();
        testStatic();
    }

    private function testInstancing() {
        var geometry = new BoxGeometry();
        var material = new MeshBasicMaterial();
        var mesh = new Mesh(geometry, material);
        var path = '.material.opacity';
        var parsedPath = {
            nodeName: '',
            objectName: 'material',
            objectIndex: null,
            propertyName: 'opacity',
            propertyIndex: null
        };

        var object = new PropertyBinding(mesh, path);
        assertTrue(object != null, 'Can instantiate a PropertyBinding.');

        var objectAll = new PropertyBinding(mesh, path, parsedPath);
        assertTrue(objectAll != null, 'Can instantiate a PropertyBinding with mesh, path, and parsedPath.');
    }

    private function testStatic() {
        todo('Composite', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('create', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        testSanitizeNodeName();

        testParseTrackName();

        todo('findNode', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('BindingType', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('Versioning', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('GetterByBindingType', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('SetterByBindingTypeAndVersioning', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('getValue', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        testSetValue();

        todo('bind', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        todo('unbind', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }

    private function testSanitizeNodeName() {
        assertEquals(PropertyBinding.sanitizeNodeName('valid-name-123_'), 'valid-name-123_',
            'Leaves valid name intact.');

        assertEquals(PropertyBinding.sanitizeNodeName('急須'), '急須',
            'Leaves non-latin unicode characters intact.');

        assertEquals(PropertyBinding.sanitizeNodeName('space separated name 123_ -'), 'space_separated_name_123__-',
            'Replaces spaces with underscores.');

        assertEquals(PropertyBinding.sanitizeNodeName('"Mátyás" %_* 😇'), '"Mátyás"_%_*_😇',
            'Allows various punctuation and symbols.');

        assertEquals(PropertyBinding.sanitizeNodeName('/invalid: name ^123.[_]'), 'invalid_name_^123_',
            'Strips reserved characters.');
    }

    private function testParseTrackName() {
        var paths:Array<Array<Dynamic>> = [
            [
                '.property',
                {
                    nodeName: null,
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'nodeName.property',
                {
                    nodeName: 'nodeName',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'a.property',
                {
                    nodeName: 'a',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'no.de.Name.property',
                {
                    nodeName: 'no.de.Name',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'no.d-e.Name.property',
                {
                    nodeName: 'no.d-e.Name',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'nodeName.property[accessor]',
                {
                    nodeName: 'nodeName',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: 'accessor'
                }
            ],

            [
                'nodeName.material.property[accessor]',
                {
                    nodeName: 'nodeName',
                    objectName: 'material',
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: 'accessor'
                }
            ],

            [
                'no.de.Name.material.property',
                {
                    nodeName: 'no.de.Name',
                    objectName: 'material',
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'no.de.Name.material[materialIndex].property',
                {
                    nodeName: 'no.de.Name',
                    objectName: 'material',
                    objectIndex: 'materialIndex',
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'uuid.property[accessor]',
                {
                    nodeName: 'uuid',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: 'accessor'
                }
            ],

            [
                'uuid.objectName[objectIndex].propertyName[propertyIndex]',
                {
                    nodeName: 'uuid',
                    objectName: 'objectName',
                    objectIndex: 'objectIndex',
                    propertyName: 'propertyName',
                    propertyIndex: 'propertyIndex'
                }
            ],

            [
                'parentName/nodeName.property',
                {
                    nodeName: 'nodeName',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'parentName/no.de.Name.property',
                {
                    nodeName: 'no.de.Name',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: null
                }
            ],

            [
                'parentName/parentName/nodeName.property[index]',
                {
                    nodeName: 'nodeName',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'property',
                    propertyIndex: 'index'
                }
            ],

            [
                '.bone[Armature.DEF_cog].position',
                {
                    nodeName: null,
                    objectName: 'bone',
                    objectIndex: 'Armature.DEF_cog',
                    propertyName: 'position',
                    propertyIndex: null
                }
            ],

            [
                'scene:helium_balloon_model:helium_balloon_model.position',
                {
                    nodeName: 'helium_balloon_model',
                    objectName: null,
                    objectIndex: null,
                    propertyName: 'position',
                    propertyIndex: null
                }
            ],

            [
                '急須.材料[零]',
                {
                    nodeName: '急須',
                    objectName: null,
                    objectIndex: null,
                    propertyName: '材料',
                    propertyIndex: '零'
                }
            ],

            [
                '📦.🎨[🔴]',
                {
                    nodeName: '📦',
                    objectName: null,
                    objectIndex: null,
                    propertyName: '🎨',
                    propertyIndex: '🔴'
                }
            ]
        ];

        for (path in paths) {
            assertEquals(PropertyBinding.parseTrackName(path[0]), path[1], 'Parses track name: ' + path[0]);
        }
    }

    private function testSetValue() {
        var paths:Array<String> = [
            '.material.opacity',
            '.material[opacity]'
        ];

        for (path in paths) {
            var originalValue = 0;
            var expectedValue = 1;

            var geometry = new BoxGeometry();
            var material = new MeshBasicMaterial();
            material.opacity = originalValue;
            var mesh = new Mesh(geometry, material);

            var binding = new PropertyBinding(mesh, path, null);
            binding.bind();

            assertEquals(material.opacity, originalValue, 'Sets property of material with "' + path + '" (pre-setValue)');

            binding.setValue([expectedValue], 0);
            assertEquals(material.opacity, expectedValue, 'Sets property of material with "' + path + '" (post-setValue)');
        }
    }

    private function todo(testName:String, testFunction:Void->Void) {
        trace('Todo: ' + testName);
        testFunction();
    }
}