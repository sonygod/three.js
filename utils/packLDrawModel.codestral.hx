import js.FileInput;
import js.FileSystem;
import js.Node;

class Main {

    static function main() {

        var ldrawPath = './';
        var materialsFileName = 'LDConfig.ldr';

        if (Node.process.argv.length != 3) {
            trace('Usage: node packLDrawModel <modelFilePath>');
            return;
        }

        var fileName = Node.process.argv[2];

        var materialsFilePath = ldrawPath + materialsFileName;

        trace('Loading materials file "' + materialsFilePath + '"...');

        var fileSystem = new FileSystem();
        var materialsContent = fileSystem.readFileSync(materialsFilePath, 'utf8');

        trace('Packing "' + fileName + '"...');

        var objectsPaths = new Array<String>();
        var objectsContents = new Array<String>();
        var pathMap = new haxe.ds.StringMap<String>();
        var listOfNotFound = new Array<String>();

        // Parse object tree
        parseObject(fileName, true);

        // Check if previously files not found are found now
        // (if so, probably they were already embedded)
        var someNotFound = false;
        for (fileName in listOfNotFound) {
            if (!pathMap.exists(fileName)) {
                someNotFound = true;
                trace('Error: File object not found: "' + fileName + '".');
            }
        }

        if (someNotFound) {
            trace('Some files were not found, aborting.');
            return;
        }

        // Obtain packed content
        var packedContent = materialsContent + '\n';
        for (var i = objectsPaths.length - 1; i >= 0; i--) {
            packedContent += objectsContents[i];
        }

        packedContent += '\n';

        // Save output file
        var outPath = fileName + '_Packed.mpd';
        trace('Writing "' + outPath + '"...');
        fileSystem.writeFileSync(outPath, packedContent);

        trace('Done.');
    }

    static function parseObject(fileName:String, isRoot:Bool = false):String {
        trace('Adding "' + fileName + '".');

        var originalFileName = fileName;

        var prefix = '';
        var objectContent:String = null;
        var attempt:Int = 0;
        while (objectContent == null && attempt < 2) {
            if (attempt == 1) {
                fileName = fileName.toLowerCase();
            }

            if (fileName.startsWith('48/')) {
                prefix = 'p/';
            } else if (fileName.startsWith('s/')) {
                prefix = 'parts/';
            }

            var absoluteObjectPath = ldrawPath + fileName;

            try {
                objectContent = fileSystem.readFileSync(absoluteObjectPath, 'utf8');
            } catch (e:Dynamic) {
                prefix = 'parts/';
                absoluteObjectPath = ldrawPath + prefix + fileName;

                try {
                    objectContent = fileSystem.readFileSync(absoluteObjectPath, 'utf8');
                } catch (e:Dynamic) {
                    prefix = 'p/';
                    absoluteObjectPath = ldrawPath + prefix + fileName;

                    try {
                        objectContent = fileSystem.readFileSync(absoluteObjectPath, 'utf8');
                    } catch (e:Dynamic) {
                        prefix = 'models/';
                        absoluteObjectPath = ldrawPath + prefix + fileName;

                        try {
                            objectContent = fileSystem.readFileSync(absoluteObjectPath, 'utf8');
                        } catch (e:Dynamic) {
                            if (attempt == 1) {
                                // The file has not been found, add to list of not found
                                listOfNotFound.push(originalFileName);
                            }
                        }
                    }
                }
            }

            attempt++;
        }

        var objectPath = (prefix + fileName).trim().replace('\\', '/');

        if (objectContent == null) {
            // File was not found, but could be a referenced embedded file.
            return null;
        }

        if (objectContent.indexOf('\r\n') != -1) {
            objectContent = objectContent.replace('\r\n', '\n');
        }

        var processedObjectContent = isRoot ? '' : '0 FILE ' + objectPath + '\n';

        var lines = objectContent.split('\n');

        for (line in lines) {
            var lineLength = line.length;

            // Skip spaces/tabs
            var charIndex = 0;
            while ((line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t') && charIndex < lineLength) {
                charIndex++;
            }

            line = line.substring(charIndex);
            lineLength = line.length;
            charIndex = 0;

            if (line.startsWith('0 FILE ')) {
                if (i == 0) {
                    // Ignore first line FILE meta directive
                    continue;
                }

                // Embedded object was found, add to path map
                var subobjectFileName = line.substring(charIndex).trim().replace('\\', '/');

                if (subobjectFileName != '') {
                    // Find name in path cache
                    var subobjectPath = pathMap.get(subobjectFileName);

                    if (subobjectPath == null) {
                        pathMap.set(subobjectFileName, subobjectFileName);
                    }
                }
            }

            if (line.startsWith('1 ')) {
                // Subobject, add it
                charIndex = 2;

                // Skip material, position and transform
                for (var token = 0; token < 13 && charIndex < lineLength; token++) {

                    // Skip token
                    while (line.charAt(charIndex) != ' ' && line.charAt(charIndex) != '\t' && charIndex < lineLength) {
                        charIndex++;
                    }

                    // Skip spaces/tabs
                    while ((line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t') && charIndex < lineLength) {
                        charIndex++;
                    }
                }

                var subobjectFileName = line.substring(charIndex).trim().replace('\\', '/');

                if (subobjectFileName != '') {
                    // Find name in path cache
                    var subobjectPath = pathMap.get(subobjectFileName);

                    if (subobjectPath == null) {
                        // Add new object
                        subobjectPath = parseObject(subobjectFileName);
                    }

                    pathMap.set(subobjectFileName, subobjectPath != null ? subobjectPath : subobjectFileName);

                    processedObjectContent += line.substring(0, charIndex) + pathMap.get(subobjectFileName) + '\n';
                }
            } else {
                processedObjectContent += line + '\n';
            }
        }

        if (!objectsPaths.contains(objectPath)) {
            objectsPaths.push(objectPath);
            objectsContents.push(processedObjectContent);
        }

        return objectPath;
    }
}