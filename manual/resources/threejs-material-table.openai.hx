package three.materials;

import js.html.Document;
import js.html.TableElement;
import js.html.TheadElement;
import js.html.TbodyElement;
import js.html.TrElement;
import js.html.TdElement;
import js.html.A;
import js.html.Element;

class MaterialTable {
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

        var table:TableElement = document.createElement('table');
        var thead:TheadElement = document.createElement('thead');
        table.appendChild(thead);

        var trh:TrElement = document.createElement('tr');
        thead.appendChild(trh);

        for (material in materials) {
            var td:TdElement = document.createElement('td');
            trh.appendChild(td);
            var a:A = document.createElement('a');
            a.href = 'https://threejs.org/docs/#api/materials/${material.name}';
            a.textContent = material.shortName;
            td.appendChild(a);
        }

        var tbody:TbodyElement = document.createElement('tbody');
        table.appendChild(tbody);

        for (property in allProperties.keys().array().sort()) {
            var tr:TrElement = document.createElement('tr');
            tbody.appendChild(tr);

            var td:TdElement = document.createElement('td');
            tr.appendChild(td);
            td.textContent = property;

            for (material in materials) {
                var hasProperty:Bool = material.properties.indexOf(property) >= 0;
                var td:TdElement = document.createElement('td');
                tr.appendChild(td);
                var a:A = document.createElement('a');
                a.href = 'https://threejs.org/docs/#api/materials/${material.name}.${property}';
                a.textContent = hasProperty ? '•' : '';
                td.appendChild(a);
            }
        }

        document.querySelector('#material-table').appendChild(table);
    }
}