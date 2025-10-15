# Login App con Flutter y Supabase

Una aplicación de autenticación completa desarrollada con Flutter y Supabase como backend.

## Características

- ✅ Pantalla de splash con verificación automática de sesión
- ✅ Registro de nuevos usuarios
- ✅ Inicio de sesión con email y contraseña
- ✅ Recuperación de contraseña
- ✅ Pantalla principal con información del usuario
- ✅ Cierre de sesión seguro
- ✅ Validación de formularios
- ✅ Manejo de errores
- ✅ Interfaz moderna y responsive

## Configuración de Supabase

### 1. Crear proyecto en Supabase

1. Ve a [https://supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Espera a que el proyecto se inicialice completamente

### 2. Obtener credenciales

1. Ve a **Settings** > **API** en tu dashboard de Supabase
2. Copia la **URL** del proyecto
3. Copia la **anon key** (clave anónima)

### 3. Configurar la aplicación

1. Copia el archivo `.env.example` y renómbralo a `.env`:
   ```bash
   cp .env.example .env
   ```

2. Abre el archivo `.env` y reemplaza los valores de ejemplo con tus credenciales reales:
   ```env
   SUPABASE_URL=https://tu-proyecto-id.supabase.co
   SUPABASE_ANON_KEY=tu_clave_anonima_real_aqui
   ```

**Importante:** El archivo `.env` contiene información sensible y no debe ser compartido públicamente. Ya está incluido en `.gitignore` para proteger tus credenciales.

### 4. Configurar autenticación en Supabase

1. Ve a **Authentication** > **Settings** en tu dashboard
2. Asegúrate de que la autenticación esté habilitada
3. Configura los proveedores de autenticación que desees usar
4. Opcionalmente, configura las URLs de redirección si planeas usar la app en web

## Instalación y ejecución

### Prerrequisitos

- Flutter SDK instalado
- Dart SDK
- Editor de código (VS Code, Android Studio, etc.)
- Emulador o dispositivo físico para pruebas

### Pasos de instalación

1. Clona o descarga este proyecto
2. Abre una terminal en el directorio del proyecto
3. Instala las dependencias:

```bash
flutter pub get
```

4. Configura Supabase como se describe arriba
5. Ejecuta la aplicación:

```bash
flutter run
```

## Estructura del proyecto

```
lib/
├── config/
│   └── supabase_config.dart    # Configuración de Supabase
├── screens/
│   ├── splash_screen.dart      # Pantalla de carga inicial
│   ├── login_screen.dart       # Pantalla de inicio de sesión
│   ├── register_screen.dart    # Pantalla de registro
│   ├── forgot_password_screen.dart # Pantalla de recuperación
│   └── home_screen.dart        # Pantalla principal
├── services/
│   └── auth_service.dart       # Servicio de autenticación
└── main.dart                   # Punto de entrada de la app
```

## Funcionalidades principales

### AuthService

El servicio de autenticación (`lib/services/auth_service.dart`) proporciona:

- `signUp()` - Registro de nuevos usuarios
- `signIn()` - Inicio de sesión
- `signOut()` - Cierre de sesión
- `resetPassword()` - Recuperación de contraseña
- `currentUser` - Usuario actual
- `isAuthenticated` - Estado de autenticación
- `authStateChanges` - Stream de cambios de estado

### Pantallas

1. **SplashScreen**: Verifica automáticamente si hay una sesión activa
2. **LoginScreen**: Formulario de inicio de sesión con validación
3. **RegisterScreen**: Formulario de registro con confirmación de contraseña
4. **ForgotPasswordScreen**: Recuperación de contraseña por email
5. **HomeScreen**: Pantalla principal con información del usuario

## Personalización

### Cambiar colores y tema

Edita el archivo `lib/main.dart` en la sección `theme` para personalizar:

- Colores primarios
- Estilos de botones
- Estilos de campos de texto
- Otros elementos de la interfaz

### Agregar campos adicionales

Para agregar campos adicionales al registro:

1. Modifica `RegisterScreen` para incluir los nuevos campos
2. Actualiza `AuthService.signUp()` para enviar los datos adicionales
3. Configura los campos en tu tabla de usuarios en Supabase

## Solución de problemas

### Error de conexión a Supabase

- Verifica que las credenciales en `supabase_config.dart` sean correctas
- Asegúrate de que tu proyecto Supabase esté activo
- Verifica tu conexión a internet

### Errores de compilación

- Ejecuta `flutter clean` y luego `flutter pub get`
- Verifica que tengas la versión correcta de Flutter
- Revisa que todas las dependencias estén instaladas

### Problemas de autenticación

- Verifica que la autenticación esté habilitada en Supabase
- Revisa los logs en el dashboard de Supabase
- Asegúrate de que el email esté confirmado (si tienes esa opción habilitada)

## Próximos pasos

Algunas mejoras que puedes implementar:

- [ ] Autenticación con Google/Apple
- [ ] Verificación de email obligatoria
- [ ] Perfil de usuario editable
- [ ] Modo oscuro
- [ ] Internacionalización (i18n)
- [ ] Notificaciones push
- [ ] Biometría (huella dactilar/Face ID)

## Contribución

Si encuentras algún error o tienes sugerencias de mejora, no dudes en crear un issue o pull request.

## Licencia

Este proyecto está bajo la licencia MIT. Puedes usarlo libremente para tus proyectos personales o comerciales.
