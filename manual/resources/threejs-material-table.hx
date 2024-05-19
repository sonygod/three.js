package three.js.manual.resources;

import js.html.Document;
import js.html.HTMLElement;
import js.html.TableElement;
import js.html.TableRowElement;
import js.html.TableDataElement;
import js.html.AnchorElement;

class ThreejsMaterialTable {
    static function main() {
        var materials:Array<Material> = [
            {
                name: 'MeshBasicMaterial',
                shortName: 'Basic',
                properties: [
                    'alphaMap',
                    'aoMap',
                    'aoMapIntensity',
                    'color',
                    'combine',
                    'envMap',
                    'lightMap',
                    'lightMapIntensity',
                    'map',
                    'reflectivity',
                    'refractionRatio',
                    'specularMap',
                    'wireframe',
                ],
            },
            {
                name: 'MeshLambertMaterial',
                shortName: 'Lambert',
                properties: [
                    'alphaMap',
                    'aoMap',
                    'aoMapIntensity',
                    'bumpMap',
                    'bumpScale',
                    'color',
                    'combine',
                    'displacementMap',
                    'displacementScale',
                    'displacementBias',
                    'emissive',
                    'emissiveMap',
                    'emissiveIntensity',
                    'envMap',
                    'lightMap',
                    'lightMapIntensity',
                    'map',
                    'normalMap',
                    'normalMapType',
                    'normalScale',
                    'reflectivity',
                    'refractionRatio',
                    'specularMap',
                    'wireframe',
                ],
            },
            {
                name: 'MeshPhongMaterial',
                shortName: 'Phong',
                properties: [
                    'alphaMap',
                    'aoMap',
                    'aoMapIntensity',
                    'bumpMap',
                    'bumpScale',
                    'color',
                    'combine',
                    'displacementMap',
                    'displacementScale',
                    'displacementBias',
                    'emissive',
                    'emissiveMap',
                    'emissiveIntensity',
                    'envMap',
                    'lightMap',
                    'lightMapIntensity',
                    'map',
                    'normalMap',
                    'normalMapType',
                    'normalScale',
                    'reflectivity',
                    'refractionRatio',
                    'shininess',
                    'specular',
                    'specularMap',
                    'wireframe',
                ],
            },
            {
                name: 'MeshStandardMaterial',
                shortName: 'Standard',
                properties: [
                    'alphaMap',
                    'aoMap',
                    'aoMapIntensity',
                    'bumpMap',
                    'bumpScale',
                    'color',
                    'displacementMap',
                    'displacementScale',
                    'displacementBias',
                    'emissive',
                    'emissiveMap',
                    'emissiveIntensity',
                    'envMap',
                    'envMapIntensity',
                    'lightMap',
                    'lightMapIntensity',
                    'map',
                    'metalness',
                    'metalnessMap',
                    'normalMap',
                    'normalMapType',
                    'normalScale',
                    'refractionRatio',
                    'roughness',
                    'roughnessMap',
                    'wireframe',
                ],
            },
            {
                name: 'MeshPhysicalMaterial',
                shortName: 'Physical',
                properties: [
                    'alphaMap',
                    'aoMap',
                    'aoMapIntensity',
                    'bumpMap',
                    'bumpScale',
                    'clearcoat',
                    'clearcoatMap',
                    'clearcoatRoughness',
                    'clearcoatRoughnessMap',
                    'clearcoatNormalScale',
                    'clearcoatNormalMap',
                    'color',
                    'displacementMap',
                    'displacementScale',
                    'displacementBias',
                    'emissive',
                    'emissiveMap',
                    'emissiveIntensity',
                    'envMap',
                    'envMapIntensity',
                    'iridescence',
                    'iridescenceMap',
                    'iridescenceIOR',
                    'iridescenceThicknessRange',
                    'iridescenceThicknessMap',
                    'lightMap',
                    'lightMapIntensity',
                    'ior',
                    'map',
                    'metalness',
                    'metalnessMap',
                    'normalMap',
                    'normalMapType',
                    'normalScale',
                    'refractionRatio',
                    'roughness',
                    'roughnessMap',
                    'sheen',
                    'sheenColor',
                    'sheenColorMap',
                    'sheenRoughness',
                    'sheenRoughnessMap',
                    'thickness',
                    'thicknessMap',
                    'transmission',
                    'transmissionMap',
                    'attenuationDistance',
                    'attenuationColor',
                    'anisotropy',
                    'anisotropyRotation',
                    'anisotropyMap',
                    'specularIntensity',
                    'specularIntensityMap',
                    'specularColor',
                    'specularColorMap',
                    'wireframe',
                    'reflectivity',
                ],
            },
        ];

        var allProperties:Map<String, Bool> = new Map();

        for (material in materials) {
            for (property in material.properties) {
                allProperties.set(property, true);
            }
        }

        function addElem(type:String, parent:HTMLElement, content:String = ''):HTMLElement {
            var elem:HTMLElement = Document.createElement(type);
            if (content != '') {
                elem.textContent = content;
            }
            if (parent != null) {
                parent.appendChild(elem);
            }
            return elem;
        }

        var table:TableElement = addElem('table');
        var thead:HTMLElement = addElem('thead', table);

        addElem('td', thead);

        for (material in materials) {
            var td:HTMLElement = addElem('td', thead);
            var a:AnchorElement = addElem('a', td, material.shortName);
            a.href = 'https://threejs.org/docs/#api/materials/${material.name}';
        }

        for (property in allProperties.keys().array().sort()) {
            var tr:TableRowElement = addElem('tr', table);
            addElem('td', tr, property);

            for (material in materials) {
                var hasProperty:Bool = Lambda.has(material.properties, property);
                var td:TableDataElement = addElem('td', tr);
                var a:AnchorElement = addElem('a', td, hasProperty ? '•' : '');
                a.href = 'https://threejs.org/docs/#api/materials/${material.name}.${property}';
            }
        }

        untyped document.querySelector('#material-table').appendChild(table);
    }
}