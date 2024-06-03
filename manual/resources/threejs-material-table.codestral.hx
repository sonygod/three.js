import js.Browser.document;
import js.html.HTMLDocument;
import js.html.HTMLTableElement;
import js.html.HTMLTableRowElement;
import js.html.HTMLTableCellElement;

class Material {
    public var name:String;
    public var shortName:String;
    public var properties:Array<String>;

    public function new(name:String, shortName:String, properties:Array<String>) {
        this.name = name;
        this.shortName = shortName;
        this.properties = properties;
    }
}

var materials:Array<Material> = [
    new Material("MeshBasicMaterial", "Basic", ["alphaMap","aoMap","aoMapIntensity","color","combine","envMap","lightMap","lightMapIntensity","map","reflectivity","refractionRatio","specularMap","wireframe"]),
    new Material("MeshLambertMaterial", "Lambert", ["alphaMap","aoMap","aoMapIntensity","bumpMap","bumpScale","color","combine","displacementMap","displacementScale","displacementBias","emissive","emissiveMap","emissiveIntensity","envMap","lightMap","lightMapIntensity","map","normalMap","normalMapType","normalScale","reflectivity","refractionRatio","specularMap","wireframe"]),
    new Material("MeshPhongMaterial", "Phong", ["alphaMap","aoMap","aoMapIntensity","bumpMap","bumpScale","color","combine","displacementMap","displacementScale","displacementBias","emissive","emissiveMap","emissiveIntensity","envMap","lightMap","lightMapIntensity","map","normalMap","normalMapType","normalScale","reflectivity","refractionRatio","shininess","specular","specularMap","wireframe"]),
    new Material("MeshStandardMaterial", "Standard", ["alphaMap","aoMap","aoMapIntensity","bumpMap","bumpScale","color","displacementMap","displacementScale","displacementBias","emissive","emissiveMap","emissiveIntensity","envMap","envMapIntensity","lightMap","lightMapIntensity","map","metalness","metalnessMap","normalMap","normalMapType","normalScale","refractionRatio","roughness","roughnessMap","wireframe"]),
    new Material("MeshPhysicalMaterial", "Physical", ["alphaMap","aoMap","aoMapIntensity","bumpMap","bumpScale","clearcoat","clearcoatMap","clearcoatRoughness","clearcoatRoughnessMap","clearcoatNormalScale","clearcoatNormalMap","color","displacementMap","displacementScale","displacementBias","emissive","emissiveMap","emissiveIntensity","envMap","envMapIntensity","iridescence","iridescenceMap","iridescenceIOR","iridescenceThicknessRange","iridescenceThicknessMap","lightMap","lightMapIntensity","ior","map","metalness","metalnessMap","normalMap","normalMapType","normalScale","refractionRatio","roughness","roughnessMap","sheen","sheenColor","sheenColorMap","sheenRoughness","sheenRoughnessMap","thickness","thicknessMap","transmission","transmissionMap","attenuationDistance","attenuationColor","anisotropy","anisotropyRotation","anisotropyMap","specularIntensity","specularIntensityMap","specularColor","specularColorMap","wireframe","reflectivity"])
];

var allProperties:haxe.ds.StringMap<Bool> = new haxe.ds.StringMap();

for (material in materials) {
    for (property in material.properties) {
        allProperties.set(property, true);
    }
}

function addElem(type:String, parent:HTMLTableElement, content:String = null):HTMLTableCellElement {
    var elem:HTMLTableCellElement = document.createElement(type).cast();

    if (content != null) {
        elem.textContent = content;
    }

    if (parent != null) {
        parent.appendChild(elem);
    }

    return elem;
}

var table:HTMLTableElement = document.createElement("table").cast();
var thead:HTMLTableRowElement = addElem("thead", table);

addElem("td", thead);

for (material in materials) {
    var td:HTMLTableCellElement = addElem("td", thead);
    var a:HTMLTableCellElement = addElem("a", td, material.shortName);
    a.href = "https://threejs.org/docs/#api/materials/" + material.name;
}

var properties:Array<String> = allProperties.keys();
properties.sort();

for (property in properties) {
    var tr:HTMLTableRowElement = addElem("tr", table);
    addElem("td", tr, property);

    for (material in materials) {
        var hasProperty:Bool = material.properties.indexOf(property) >= 0;
        var td:HTMLTableCellElement = addElem("td", tr);
        var a:HTMLTableCellElement = addElem("a", td, hasProperty ? "•" : "");
        a.href = "https://threejs.org/docs/#api/materials/" + material.name + "." + property;
    }
}

document.querySelector("#material-table").appendChild(table);