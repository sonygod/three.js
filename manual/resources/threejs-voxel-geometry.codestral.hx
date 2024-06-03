import three.THREE;
import three.examples.utils.BufferGeometryUtils;
import resources.threejsLessonUtils;

class Main {

    public static function main() {

        var darkMatcher = js.Browser.window.matchMedia( '(prefers-color-scheme: dark)' );
        var isDarkMode = darkMatcher.matches;

        var darkColors = {
            wire: 0xDDD
        };
        var lightColors = {
            wire: 0x000
        };
        var colors = isDarkMode ? darkColors : lightColors;

        threejsLessonUtils.addDiagrams( {
            mergedCubes: {
                create: function() {

                    var geometries = new Array<THREE.BufferGeometry>();
                    var width = 3;
                    var height = 2;
                    var depth = 2;
                    for ( var y = 0; y < height; ++y ) {

                        for ( var z = 0; z < depth; ++z ) {

                            for ( var x = 0; x < width; ++x ) {

                                var geometry = new THREE.BoxGeometry( 1, 1, 1 );
                                geometry.applyMatrix4( ( new THREE.Matrix4() ).makeTranslation( x, y, z ) );
                                geometries.push( geometry );

                            }

                        }

                    }

                    var mergedGeometry = BufferGeometryUtils.mergeGeometries( geometries, false );
                    var material = new THREE.MeshBasicMaterial( {
                        color: colors.wire,
                        wireframe: true
                    } );
                    var mesh = new THREE.Mesh( mergedGeometry, material );
                    mesh.position.set(
                        0.5 - width / 2,
                        0.5 - height / 2,
                        0.5 - depth / 2 );
                    var base = new THREE.Object3D();
                    base.add( mesh );
                    base.scale.setScalar( 3.5 );
                    return base;

                }
            },
            culledCubes: {
                create: function() {

                    var geometry = new THREE.BoxGeometry( 3, 2, 2, 3, 2, 2 );
                    var material = new THREE.MeshBasicMaterial( {
                        color: colors.wire,
                        wireframe: true
                    } );
                    var mesh = new THREE.Mesh( geometry, material );
                    mesh.scale.setScalar( 3.5 );
                    return mesh;

                }
            }
        } );

    }

}