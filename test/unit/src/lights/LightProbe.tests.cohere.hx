import js.QUnit;

import js.src.lights.LightProbe;
import js.src.lights.Light;

class LightsTest {
    public static function main() {
        QUnit.module('Lights', {
            setup:function() {
            }, teardown:function() {
            }
        }, function() {
            QUnit.module('LightProbe', {
                setup:function() {
                }, teardown:function() {
                }
            }, function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new LightProbe();
                    assert.strictEqual(object instanceof Light, true, 'LightProbe extends from Light');
                });

                // INSTANCING
                QUnit.todo('Instancing', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PROPERTIES
                QUnit.todo('sh', function(assert) {
                    // SphericalHarmonics3 if not supplied
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isLightProbe', function(assert) {
                    var object = new LightProbe();
                    assert.ok(object.isLightProbe, 'LightProbe.isLightProbe should be true');
                });

                QUnit.todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fromJSON', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('toJSON', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}