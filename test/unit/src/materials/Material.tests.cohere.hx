import haxe.unit.TestCase;
import js.Browser;
import js.html.Document;
import js.html.Window;
import js.html.HTMLElement;
import js.lib.Document;
import js.node.Event;

import h3d.Material;
import h3d.core.EventDispatcher;

class TestMaterial extends TestCase {
    static function testExtending() {
        var material = new Material();
        var assert = Browser.window.QUnit.ok(
            material instanceof EventDispatcher,
            'Material extends from EventDispatcher'
        );
    }

    static function testInstancing() {
        var material = new Material();
        var assert = Browser.window.QUnit.ok(material, 'Can instantiate a Material.');
    }

    static function testType() {
        var material = new Material();
        var assert = Browser.window.QUnit.ok(
            material.getType() == 'Material',
            'Material.type should be Material'
        );
    }

    static function testIsMaterial() {
        var material = new Material();
        var assert = Browser.window.QUnit.ok(
            material.isMaterial,
            'Material.isMaterial should be true'
        );
    }

    static function testDispose() {
        var material = new Material();
        material.dispose();
    }
}

class haxe_test_TestRunner {
    static function main() {
        #if js
        var window = js.Browser.window;
        #end
        #if js
        var qunit = (window as Dynamic).QUnit;
        #end
        var doc = js.lib.Document.create();
        var qunitDiv = doc.createElement('div');
        qunitDiv.id = 'qunit';
        doc.body.appendChild(qunitDiv);
        #if js
        qunit.module('Materials', function () {
            qunit.module('Material', function () {
                qunit.test('Extending', TestMaterial.testExtending);
                qunit.test('Instancing', TestMaterial.testInstancing);
                qunit.test('Type', TestMaterial.testType);
                qunit.test('IsMaterial', TestMaterial.testIsMaterial);
                qunit.test('Dispose', TestMaterial.testDispose);
            });
        });
        #end
    }
}