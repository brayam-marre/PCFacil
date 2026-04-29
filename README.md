# PCFacil

Herramienta de diagnóstico y limpieza para usuarios no técnicos. Permite revisar el estado del equipo, liberar espacio y generar un reporte de mejoras en lenguaje sencillo, sin conocimientos de informática.

## Ejecución rápida

```powershell
iwr -useb https://raw.githubusercontent.com/brayam-marre/PCFacil/main/install.ps1 | iex
```

> Requiere PowerShell 5.1+ y ejecución como Administrador.

El comando descarga PCFacil, lo ejecuta y elimina los archivos automáticamente al cerrar. No instala nada de forma permanente.

---

## Funciones

| Opción | Descripción |
|---|---|
| **Ver cómo está mi PC** | Muestra el estado del procesador, RAM, disco y sistema operativo con explicación en lenguaje simple y una puntuación general del equipo |
| **Limpiar mi PC** | Elimina archivos temporales, caché de navegadores (Chrome y Firefox), Papelera de reciclaje, caché de Windows Update y logs antiguos. No borra documentos, fotos ni programas |
| **Generar reporte** | Crea un archivo HTML en el Escritorio con el diagnóstico completo, puntuación del equipo, mejoras recomendadas con costos en CLP y sistema operativo sugerido |
| **Contactar al técnico** | Muestra los datos de contacto para soporte presencial (Yumbel) o remoto (todo Chile) |

---

## Qué limpia y qué NO limpia

**Limpia:**
- Archivos temporales del sistema y del usuario
- Caché de Google Chrome (`\Default\Cache`)
- Caché de Mozilla Firefox (`\cache2` por perfil)
- Papelera de reciclaje
- Caché de Windows Update (`SoftwareDistribution\Download`)
- Logs del sistema mayores a 30 días

**No toca:**
- Documentos, fotos, música, descargas
- Contraseñas guardadas en navegadores
- Historial de navegación, marcadores, extensiones
- Programas instalados

---

## Reporte HTML

El reporte se guarda en el Escritorio como `Reporte_PC_[fecha].html` e incluye:

- Puntuación general del equipo (0–100)
- Estado de procesador, RAM, disco y sistema operativo
- Lista de mejoras recomendadas con costo aproximado en CLP
- Sistema operativo recomendado según el hardware

---

## Características

- Sin instalación — un solo comando lo descarga, ejecuta y elimina los archivos al cerrar
- Solicita privilegios de administrador automáticamente
- Lenguaje claro, sin términos técnicos
- Se autoeliminan los archivos si se ejecuta desde una carpeta temporal
- Compatible con Windows 10 y Windows 11

---

## Estructura del proyecto

```
PCFacil/
├── install.ps1               <- Instalador one-liner
├── PCFacil.ps1               <- Script principal y menú
└── modules/
    ├── diagnostico.ps1       <- Análisis del equipo y puntuación
    ├── limpieza.ps1          <- Limpieza de archivos temporales y caché
    └── reporte.ps1           <- Generación de reporte HTML
```