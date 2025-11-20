# MyDearMap

MyDearApp es un proyecto combinado entre etsinf y bellas artes de la Universitat Politècnica de València.
Sus autores son Cristian, Oscar, Nacho (programadores), Silvia e Ivonne (diseñadoras).

## Descripción

MyDearMap permite a los usuarios:

- Crear recuerdos con título, descripción, fecha, ubicación y media.
- Añadir personas a esos recuerdos, reaccionar y comentar en recuerdos.
- Ver esos recuerdos en un mapa interactivo.
- Relacionar recuerdos entre sí mediante una línea de tiempo.
- Explorar dicha "timeline".
- Añadir ubicaciones a la "wishlist".

La app busca ser cálida, íntima, nostalgica, cercana, y servir como diario virtual colaborativo.

## Prerrequisitos

Necesitarás tener instalado:

* **Flutter SDK 3.35.4** o superior.
* **Git** para clonar el repositorio.

## Instalación y uso

### 1. Clonar repositorio

```bash
git clone https://github.com/HyCrisXXI/mydearmap.git
cd mydearmap
```

### 2. Configurar variables de entorno

1. Obtener las claves API necesarias.
2. Duplicar el archivo .env.example y llamarlo .env.
3. Añadir las claves a cada variable de entorno del .env.

### 3. Instalar dependencias de Flutter

```bash
flutter pub get
```

### 4. Ejecutar la aplicación

```bash
flutter run
```

## Principales características

- Mapa con marcadores de recuerdos
- Formulario para crear / editar recuerdos
- Vista tipo línea / grafo de relaciones
- Relaciones personalizadas entre usuarios
- Autenticación (login / registro)
- Persistencia local (Drift) + sincronización con Supabase
- Temas / estilos globales reutilizables
- Widgets personalizados reutilizables
- Navegación estructurada con rutas definidas
- Estilo minimalista, cálido, cercano...
- Chat con IA basado en Gemini 1.5 Flash

### Chat con Gemini

- El controlador `ai_chat_controller.dart` invoca el endpoint `gemini-2.0-flash` (v1beta).
- Antes de cada petición, el controlador resume los últimos recuerdos del usuario y los envía como contexto para que la IA pueda contestar preguntas como "dame los recuerdos de este mes".
- Añade tu `GEMINI_API_KEY` al `.env` para habilitar las peticiones.
- El historial completo del chat se envía en cada llamada para conservar el contexto.
- Puedes ajustar temperatura y tokens máximos en `GeminiChatService` si necesitas respuestas más creativas o largas.

## Arquitectura

- Lenguaje: Flutter + Dart
- Backend: Supabase (auth + BD)
- Almacenamiento local offline: Hive
- Arquitectura en capas: presentación / controladores / datos / servicios
- Modularización en widgets reutilizables
- OpenStreetMap con MapTiler

## Estructura

La estructura principal del proyecto sigue un diseño modular:
```text
lib/
├── main.dart               # Entry point de la app
├── app.dart                # Configuración de rutas, themes, providers
├── core/                   # Funciones y utilidades comunes
│   ├── constants/          # Colores, tamaños, strings, apis
│   ├── utils/              # Helpers generales (fechas, mapas, imágenes, excepciones)
│   ├── providers/          # Proveedores de estado global
│   ├── widgets/            # Widgets reutilizables de toda la app
│   └── errors/             # Distintos tipos de errores
├── data/                   # Acceso a datos, API, local storage
│   ├── models/             # Modelos de objetos (User, Memory, MapPin)
│   ├── repositories/       # Lógica de acceso a datos (abstract + impl)
│   └── datasources/        # APIs
├── features/               # Cada "pantalla" o feature principal
│   ├── auth/               # Auth view
│   │   ├── views/          # Widgets y pantallas
│   │   ├── controllers/    # State, bloc, cubit o provider
│   │   ├── models/         # Modelos específicos de auth
│   │   └── widgets/        # Componentes específicos de auth
│   ├── map/
│   ├── memories/
│   └── timeline/
└── routes/                 # Rutas/navegación
```

## Recursos de interés

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
