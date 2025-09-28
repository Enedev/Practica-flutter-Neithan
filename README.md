# Flutter CRUD App con Provider y DummyJSON API

Este proyecto es una aplicación móvil desarrollada en **Flutter** que muestra el uso del **Provider** para realizar un **CRUD** (Crear, Leer, Actualizar, Eliminar) completo con una api pública.

## API Seleccionada: DummyJSON API

La aplicación utiliza la **DummyJSON API** (`https://dummyjson.com`) como *backend* para probar el uso del **Provider** y de el manejo de utilización de una API.

### ¿Qué es DummyJSON?

DummyJSON es una API gratuita y de código abierto diseñada para servir como un **punto de *mocking*** (simulación) para desarrolladores que necesitan datos JSON de prueba para proyectos *frontend* sin la necesidad de configurar un servidor real.

### Funcionalidades Específicas en la Aplicación

El archivo `ApiService` del proyecto implementa las siguientes operaciones de la API:

| Operación | Método HTTP | Endpoint de la API | Descripción |
| :--- | :--- | :--- | :--- |
| **READ** (Paginación) | `GET` | `/products?limit={}&skip={}` | **Carga inicial y paginada** de la lista de productos. |
| **SEARCH** | `GET` | `/products/search?q={}` | Permite **filtrar** la lista de productos por un término de búsqueda. |
| **CREATE** (Añadir) | `POST` | `/products/add` | **Agrega** un nuevo producto a la lista. |
| **UPDATE** (Editar) | `PUT` | `/products/{id}` | **Modifica** los datos de un producto existente. |
| **DELETE** | `DELETE` | `/products/{id}` | **Elimina** un producto. |

**Nota sobre la Simulación:** DummyJSON simula las operaciones CRUD. Las acciones `POST`, `PUT`, y `DELETE` se realizan correctamente y devuelven respuestas HTTP de éxito (`201` o `200`), pero **los datos no persisten** en el servidor, por eso se usa con fines de prueba *frontend*.

---

### Explicacion de mi ProductProvider

La aplicación utiliza la clase **ProductProvider** para gestionar el estado de los productos y orquestar las operaciones de la API, manejando la lógica central de la aplicación.

En **ProductProvider**  implemente la lógica para la busqueda, al inicio tuve un problema con la paginación (scroll infinito), explicación del como realice el buscado para solucionar este problema :

- Al inicio, al buscar, la aplicación solo podía **filtrar entre los datos que ya habían sido cargados** (por medio del scroll infinito y la función `loadMoreProducts` no sobre el catálogo completo de la API.

Para resolver esto, ideé una solución de **doble lista y fusión de "caché"**, básicamente fusiono dos listas, una que busca (`_searchResults`) y carga los productos buscados, y otra que es el de la screen principal (`_products`), y luego las junto para que se refleje el mismo manejo de CRUD en ambas:

1.  **(`_mergeProducts`)**: Cuando el usuario escribe una consulta (`updateSearchQuery`), el *provider* **primero llama a la API** (`/products/search?q={}`) para obtener todos los productos que coinciden con la búsqueda. Estos resultados se **fusionan** (`_mergeProducts`) inmediatamente en la caché principal (`_products`).

2.  **Lista de Resultados Separada (`_searchResults`)**: Después de la fusión, los productos filtrados se guardan en la lista separada `_searchResults`.

3.  **Resultado**: Esto asegura que la búsqueda siempre sea **global (sobre la API completa)** y, al mismo tiempo, **sincroniza** los resultados globales con la lista local paginada, garantizando que el usuario tenga acceso a todos los productos relevantes, incluso si no habían sido cargados por el *scroll* infinito.

---

## Video del funcionamiento de la Aplicación

**[VIDEO LINK GOES HERE]**

---

## Cómo Ejecutar el Proyecto

Sigue los siguientes pasos probar el codigo:

1.  **Clonar el Repositorio:**
    ```bash
    git clone https://github.com/Enedev/Practica-flutter-Neithan
    cd [nombre del repositorio]
    ```

2.  **Obtener Dependencias:**
    Ejecuta el siguiente comando para descargar todos los paquetes necesarios definidos en `pubspec.yaml`:
    ```bash
    flutter pub get
    ```

3.  **Ejecutar la Aplicación:**
    Asegúrate de tener un dispositivo o emulador conectado y activo.
    ```bash
    flutter run
    ```