# mydearmap

MyDearApp es un proyecto combinado entre etsinf y bellas artes de la Universitat Politècnica de València.
Sus autores son Cris, Oscar, Nacho (programadores), Silvia e Ivonne (diseñadoras)

## Descripción

MyDearMap permite a los usuarios:

- Crear recuerdos con título, descripción, fecha, ubicación y media.
- Añadir personas a esos recuerdos, reaccionar y comentar en recuerdos.
- Ver esos recuerdos en un mapa interactivo.
- Relacionar recuerdos entre sí mediante una línea de tiempo.
- Explorar dicha "timeline".
- Añadir ubicaciones a la "wishlist".

La app busca ser cálida, íntima, nostalgica, minimalista, cercana, y servir como diario virtual colaborativo.

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

## Arquitectura

- Lenguaje: Flutter + Dart
- Backend: Supabase (auth + BD)
- Almacenamiento local offline: Hive
- Arquitectura en capas: presentación / controladores / datos / servicios
- Modularización en widgets reutilizables
- Google maps

## Estructura

lib/
├── main.dart                   # Entry point de la app
├── app.dart                    # Configuración de rutas, themes, providers
├── core/                       # Funciones y utilidades comunes
│   ├── constants/              # Colores, tamaños, strings
│   ├── utils/                  # Helpers generales (fechas, mapas, imágenes, excepciones)
│   ├── providers/
│   └── widgets/                # Widgets reutilizables de toda la app
├── data/                       # Acceso a datos, API, local storage
│   ├── models/                 # Modelos de objetos (User, Memory, MapPin)
│   ├── repositories/           # Lógica de acceso a datos (abstract + impl)
│   └── datasources/            # APIs
├── features/                   # Cada "pantalla" o feature principal
│   ├── map/                    # Map view
│   │   ├── views/               # Widgets y pantallas
│   │   ├── controllers/         # State, bloc, cubit o provider
│   │   └── widgets/            # Componentes específicos de map
│   ├── timeline/
│   │   ├── views/
│   │   ├── controllers/
│   │   └── widgets/
│   ├── memories/
│   ├── users/
│   └── settings/
└── routes/                     # Rutas/navegación

## Recursos de interés

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
