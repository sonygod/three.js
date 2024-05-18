import MMDLoader;

class Main {
public static function main() {
var loader = new MMDLoader();
loader.load('path/to/model.pmx', function (model) {
// do something with the loaded model
}, null, null);
}
}
```

And then run the following command: