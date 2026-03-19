# Pro-Tocol: SSH Visual Client

Aplicación móvil desarrollada en Flutter que permite la administración remota de servidores Linux a través de una interfaz gráfica intuitiva, eliminando la dependencia obligatoria de la terminal para tareas comunes.

## Definición del Proyecto

El sistema permite la conexión a servidores mediante el protocolo SSH, organizando el acceso a través de perfiles de usuario. La aplicación se distingue por ofrecer un entorno visual para la gestión de archivos, monitoreo de recursos y despliegue de servicios mediante plantillas preconfiguradas.

### Características Principales

* **Sistema de Perfiles:** Acceso multiusuario con configuraciones personalizadas para cada perfil al estilo de plataformas de streaming.
* **Gestor de Servidores:** Configuración visual de aplicaciones y servicios sin necesidad de comandos manuales.
* **Despliegue por Plantillas:** Instalación automatizada de stacks (Web, Base de Datos) mediante checklists de validación y configuraciones básicas automáticas.
* **Explorador de Archivos:** Gestión funcional para subir, descargar, editar y codificar archivos de texto con editor integrado.
* **Monitoreo en Tiempo Real:** Visualización del estado del hardware (CPU, RAM, Disco), procesos y puertos activos.
* **Asistente de IA:** Chat integrado conectado a una API propia (Ollama) para la generación y ejecución supervisada de scripts en el servidor.

---

## Especificaciones Técnicas

* **Framework:** Flutter
* **Comunicación SSH:** Librería dartssh2
* **Backend IA:** API propia basada en Ollama
* **Arquitectura:** División en tres capas (Presentación, Dominio y Datos)
* **Patrón de Diseño:** MVC (Modelo-Vista-Controlador)

---

## Planificación: Sprint 1

El objetivo de este primer bloque es establecer la base de conectividad, la persistencia de perfiles y la navegación visual básica.

### Estructura de Interfaz

1.  **Pantalla de Perfiles:** Creación y selección de perfiles con nombre y avatar.
2.  **Sidebar (Menú Lateral):** Ubicación de servidores guardados, sesiones temporales y botones de creación/eliminación.
3.  **Formularios:** Captura de credenciales (Usuario, IP, Contraseña o Key).
4.  **Vistas de Servidor:**
    * Pestaña de Estado: Monitoreo de hardware (CPU, RAM, Disco).
    * Pestaña de Terminal: Consola interactiva funcional.
    * Pestaña de Explorador: Visualización de archivos y directorios (Solo vista).

---

## Backlog del Sprint 1: Conectividad y Estructura Base

| ID | Rol | Historia de Usuario | Descripción / Criterios de Aceptación | SP |
| :--- | :--- | :--- | :--- | :--- |
| **US-A1** | **Dev A (View)** | **Gestor de Perfiles** | Pantalla inicial estilo Netflix para crear/seleccionar perfil (Nombre y Avatar). | 3 |
| **US-A2** | **Dev A (View)** | **Layout y Sidebar** | Menú lateral con secciones para Servidores y Sesiones Temporales. Botones de añadir/eliminar. | 5 |
| **US-A3** | **Dev A (View)** | **Formularios de Conexión** | Interfaz para capturar IP, Usuario, Password o Key. Validación visual de campos. | 3 |
| **US-A4** | **Dev A (View)** | **Pestañas de Servidor** | Implementación de TabController: Estado (Monitoreo), Terminal y Explorador. | 5 |
| **US-B1** | **Dev B (Model)** | **Entidades de Dominio** | Definición de clases Profile, Server, TempSession, ServerStats y FileItem. | 2 |
| **US-B2** | **Dev B (Model)** | **Persistencia Local** | Configuración de DB (Hive/Isar) para perfiles y servidores guardados. | 5 |
| **US-B3** | **Dev B (Model)** | **Motor SSH y SFTP** | Implementación de `dartssh2`. Métodos para ejecutar comandos y listar archivos. | 8 |
| **US-C1** | **Dev C (Controller)** | **Navegación y Perfiles** | Lógica para cambiar de perfil y gestionar qué componente se muestra en el Sidebar. | 5 |
| **US-C2** | **Dev C (Controller)** | **Orquestador SSH** | Manejo de sesiones activas en paralelo y gestión de errores de conexión. | 5 |
| **US-C3** | **Dev C (Controller)** | **Lógica de Pestañas** | Timers para métricas de CPU/RAM, gestión de streams de terminal y navegación SFTP. | 8 |
| **TOTAL** | | | **Carga balanceada: Dev A (16), Dev B (15), Dev C (18)** | **49** |

---

## Criterios de Aceptación Generales (DoD)
1. **Conexión Exitosa:** Se debe lograr el acceso a un servidor Linux real desde la app.
2. **Persistencia:** Al reiniciar la app, los perfiles y servidores creados deben seguir ahí.
3. **Multitarea:** Se debe poder abrir una terminal en una sesión temporal y otra en un servidor guardado simultáneamente.
4. **Monitoreo:** La pestaña de estado debe mostrar datos reales de CPU, RAM y Disco del servidor.
5. **Navegación:** El explorador debe listar archivos de cualquier ruta solicitada (ej. `/etc` o `/var`).
## Notas de Implementación

* Las **Sesiones Temporales** no se persisten en la base de datos local; se eliminan al cerrar la aplicación o la sesión.
* El **Explorador de Archivos** en el Sprint 1 se limita a la visualización de la estructura de directorios para asegurar estabilidad.
* La arquitectura debe garantizar que las tres pestañas del servidor mantengan su estado independiente durante la conexión activa.