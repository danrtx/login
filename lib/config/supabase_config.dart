import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Las credenciales ahora se cargan desde el archivo .env
  // Asegúrate de configurar tu archivo .env con:
  // SUPABASE_URL=https://tu-proyecto-id.supabase.co
  // SUPABASE_ANON_KEY=tu_clave_anonima_aqui
  
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL no está configurada en el archivo .env. '
        'Por favor, agrega tu URL de Supabase al archivo .env'
      );
    }
    return url;
  }
  
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY no está configurada en el archivo .env. '
        'Por favor, agrega tu clave anónima de Supabase al archivo .env'
      );
    }
    return key;
  }
}

// INSTRUCCIONES PARA CONFIGURAR SUPABASE:
// 
// 1. Ve a https://supabase.com y crea una cuenta
// 2. Crea un nuevo proyecto
// 3. Ve a Settings > API en tu dashboard
// 4. Copia la URL del proyecto y la clave anónima (anon key)
// 5. Reemplaza los valores arriba con tus credenciales reales
// 6. Asegúrate de que la autenticación esté habilitada en tu proyecto Supabase
//
// NOTA DE SEGURIDAD:
// En una aplicación real, considera usar variables de entorno
// o archivos de configuración separados para diferentes entornos
// (desarrollo, staging, producción)