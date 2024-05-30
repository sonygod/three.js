package;

import js.QUnit;
import js.WebGLRenderLists;
import js.WebGLRenderList;
import js.Scene;

class Renderers {
    public static function runTests() {
        QUnit.module('Renderers', function() {
            QUnit.module('WebGL', function() {
                QUnit.module('WebGLRenderLists', function() {
                    // PUBLIC
                    QUnit.test('get', function() {
                        var renderLists = new WebGLRenderLists();
                        var sceneA = new Scene();
                        var sceneB = new Scene();

                        var listA = renderLists.get(sceneA);
                        var listB = renderLists.get(sceneB);

                        QUnit.propEqual(listA, new WebGLRenderList(), 'listA is type of WebGLRenderList.');
                        QUnit.propEqual(listB, new WebGLRenderList(), 'listB is type of WebGLRenderList.');
                        QUnit.ok(listA != listB, 'Render lists are different.');
                    });
                });

                QUnit.module('WebGLRenderList', function() {
                    QUnit.test('init', function() {
                        var list = new WebGLRenderList();

                        QUnit.ok(list.transparent.length == 0, 'Transparent list defaults to length 0.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list defaults to length 0.');

                        list.push({}, {}, { transparent : true }, 0, 0, {});
                        list.push({}, {}, { transparent : false }, 0, 0, {});

                        QUnit.ok(list.transparent.length == 1, 'Transparent list is length 1 after adding transparent item.');
                        QUnit.ok(list.opaque.length == 1, 'Opaque list list is length 1 after adding opaque item.');

                        list.init();

                        QUnit.ok(list.transparent.length == 0, 'Transparent list is length 0 after calling init.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list list is length 0 after calling init.');
                    });

                    QUnit.test('push', function() {
                        var list = new WebGLRenderList();
                        var objA = { id : 'A', renderOrder : 0 };
                        var matA = { transparent : true };
                        var geoA = {};

                        var objB = { id : 'B', renderOrder : 0 };
                        var matB = { transparent : true };
                        var geoB = {};

                        var objC = { id : 'C', renderOrder : 0 };
                        var matC = { transparent : false };
                        var geoC = {};

                        var objD = { id : 'D', renderOrder : 0 };
                        var matD = { transparent : false };
                        var geoD = {};

                        list.push(objA, geoA, matA, 0, 0.5, {});
                        QUnit.ok(list.transparent.length == 1, 'Transparent list is length 1 after adding transparent item.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list list is length 0 after adding transparent item.');
                        QUnit.deepEqual(
                            list.transparent[0],
                            {
                                id : 'A',
                                object : objA,
                                geometry : geoA,
                                material : matA,
                                groupOrder : 0,
                                renderOrder : 0,
                                z : 0.5,
                                group : {}
                            },
                            'The first transparent render list item is structured correctly.'
                        );

                        list.push(objB, geoB, matB, 1, 1.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding second transparent item.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list list is length 0 after adding second transparent item.');
                        QUnit.deepEqual(
                            list.transparent[1],
                            {
                                id : 'B',
                                object : objB,
                                geometry : geoB,
                                material : matB,
                                groupOrder : 1,
                                renderOrder : 0,
                                z : 1.5,
                                group : {}
                            },
                            'The second transparent render list item is structured correctly.'
                        );

                        list.push(objC, geoC, matC, 2, 2.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding first opaque item.');
                        QUnit.ok(list.opaque.length == 1, 'Opaque list list is length 1 after adding first opaque item.');
                        QUnit.deepEqual(
                            list.opaque[0],
                            {
                                id : 'C',
                                object : objC,
                                geometry : geoC,
                                material : matC,
                                groupOrder : 2,
                                renderOrder : 0,
                                z : 2.5,
                                group : {}
                            },
                            'The first opaque render list item is structured correctly.'
                        );

                        list.push(objD, geoD, matD, 3, 3.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding second opaque item.');
                        QUnit.ok(list.opaque.length == 2, 'Opaque list list is length 2 after adding second opaque item.');
                        QUnit.deepEqual(
                            list.opaque[1],
                            {
                                id : 'D',
                                object : objD,
                                geometry : geoD,
                                material : matD,
                                groupOrder : 3,
                                renderOrder : 0,
                                z : 3.5,
                                group : {}
                            },
                            'The second opaque render list item is structured correctly.'
                        );
                    });

                    QUnit.test('unshift', function() {
                        var list = new WebGLRenderList();
                        var objA = { id : 'A', renderOrder : 0 };
                        var matA = { transparent : true };
                        var geoA = {};

                        var objB = { id : 'B', renderOrder : 0 };
                        var matB = { transparent : true };
                        var geoB = {};

                        var objC = { id : 'C', renderOrder : 0 };
                        var matC = { transparent : false };
                        var geoC = {};

                        var objD = { id : 'D', renderOrder : 0 };
                        var matD = { transparent : false };
                        var geoD = {};


                        list.unshift(objA, geoA, matA, 0, 0.5, {});
                        QUnit.ok(list.transparent.length == 1, 'Transparent list is length 1 after adding transparent item.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list list is length 0 after adding transparent item.');
                        QUnit.deepEqual(
                            list.transparent[0],
                            {
                                id : 'A',
                                object : objA,
                                geometry : geoA,
                                material : matA,
                                groupOrder : 0,
                                renderOrder : 0,
                                z : 0.5,
                                group : {}
                            },
                            'The first transparent render list item is structured correctly.'
                        );

                        list.unshift(objB, geoB, matB, 1, 1.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding second transparent item.');
                        QUnit.ok(list.opaque.length == 0, 'Opaque list list is length 0 after adding second transparent item.');
                        QUnit.deepEqual(
                            list.transparent[0],
                            {
                                id : 'B',
                                object : objB,
                                geometry : geoB,
                                material : matB,
                                groupOrder : 1,
                                renderOrder : 0,
                                z : 1.5,
                                group : {}
                            },
                            'The second transparent render list item is structured correctly.'
                        );

                        list.unshift(objC, geoC, matC, 2, 2.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding first opaque item.');
                        QUnit.ok(list.opaque.length == 1, 'Opaque list list is length 1 after adding first opaque item.');
                        QUnit.deepEqual(
                            list.opaque[0],
                            {
                                id : 'C',
                                object : objC,
                                geometry : geoC,
                                material : matC,
                                groupOrder : 2,
                                renderOrder : 0,
                                z : 2.5,
                                group : {}
                            },
                            'The first opaque render list item is structured correctly.'
                        );

                        list.unshift(objD, geoD, matD, 3, 3.5, {});
                        QUnit.ok(list.transparent.length == 2, 'Transparent list is length 2 after adding second opaque item.');
                        QUnit.ok(list.opaque.length == 2, 'Opaque list list is length 2 after adding second opaque item.');
                        QUnit.deepEqual(
                            list.opaque[0],
                            {
                                id : 'D',
                                object : objD,
                                geometry : geoD,
                                material : matD,
                                groupOrder : 3,
                                renderOrder : 0,
                                z : 3.5,
                                group : {}
                            },
                            'The second opaque render list item is structured correctly.'
                        );
                    });

                    QUnit.test('sort', function() {
                        var list = new WebGLRenderList();
                        var items = [ { id : 4 }, { id : 5 }, { id : 2 }, { id : 3 } ];

                        items.forEach(function(item) {

                            list.push(item, {}, { transparent : true }, 0, 0, {});
                            list.push(item, {}, { transparent : false }, 0, 0, {});

                        });

                        list.sort(function(a, b) {
                            return a.id - b.id;
                        }, function(a, b) {
                            return b.id - a.id;
                        });

                        QUnit.deepEqual(
                            list.opaque.map(function(item) {
                                return item.id;
                            }),
                            [ 2, 3, 4, 5 ],
                            'The opaque sort is applied to the opaque items list.'
                        );

                        QUnit.deepEqual(
                            list.transparent.map(function(item) {
                                return item.id;
                            }),
                            [ 5, 4, 3, 2 ],
                            'The transparent sort is applied to the transparent items list.'
                        );
                    });
                });
            });
        });
    }
}

Renderers.runTests();