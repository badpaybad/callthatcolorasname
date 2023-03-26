package nguyenphandu.online.callthatcolorasname
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
//import nguyenphandu.online.callthatcolorasname

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        //Log.e("MainActivity", "MainActivity----------------------override configureFlutterEngine")
        //System.setProperty("log.tag.Zygote", "ERROR")
        try {
            flutterEngine.getPlugins().add( nguyenphandu.online.callthatcolorasname.SoundStreamPlugin())
            Log.i("MainActivity", "flutterEngine.getPlugins().add( nguyenphandu.online.callthatcolorasname.SoundStreamPlugin())")
        } catch(e: Exception ) {
            Log.e("MainActivity", "Error flutterEngine.getPlugins().add( nguyenphandu.online.callthatcolorasname.SoundStreamPlugin())", e)
        }
    }

//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        // Launch the Flutter app
//        Log.i("MainActivity", "override fun onCreate(savedInstanceState: Bundle?)")
//    }

    /*

    try {
      flutterEngine.getPlugins().add(new nguyenphandu.online.callthatcolorasname.SoundStreamPlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin sound_stream, nguyenphandu.online.callthatcolorasname.SoundStreamPlugin", e);
    }
    * */
}
