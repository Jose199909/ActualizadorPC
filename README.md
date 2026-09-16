# ActualizadorPC

[English version](README.en.md)

Aplicación gráfica para Windows 11 que reúne en una sola ventana la búsqueda e instalación de actualizaciones de:

- Windows Update
- Microsoft Defender
- Programas compatibles con `winget`

El usuario decide qué elementos instalar. La aplicación no desinstala programas ni reinicia el equipo automáticamente.

## Características

- Interfaz gráfica sencilla en español.
- Búsqueda conjunta de actualizaciones del sistema, Defender y aplicaciones.
- Selección individual de los elementos que se instalarán.
- Registro visible del resultado de cada operación.
- Aviso cuando Windows solicita reiniciar.
- Procesamiento en segundo plano para mantener la interfaz disponible.

## Requisitos

- Windows 11.
- Windows PowerShell 5.1.
- App Installer y `winget` disponibles en el equipo.
- Conexión a Internet.
- Permisos de administrador cuando Windows o un instalador los solicite.

## Instalación

1. Descarga el repositorio mediante **Code > Download ZIP**.
2. Extrae el archivo ZIP en una carpeta de tu elección.
3. Conserva `Iniciar.cmd` y `ActualizadorPC.ps1` en la misma carpeta.

También puedes clonar el proyecto:

```powershell
git clone https://github.com/Jose199909/ActualizadorPC.git
```

## Uso

1. Haz doble clic en `Iniciar.cmd`.
2. Pulsa **Buscar actualizaciones**.
3. Marca los elementos que quieras instalar.
4. Pulsa **Instalar seleccionadas**.
5. Revisa el resultado mostrado en la parte inferior.

Si Windows solicita permisos de administrador, revisa el aviso y acéptalo para continuar con la actualización correspondiente.

## Cómo funciona

`ActualizadorPC.ps1` consulta las actualizaciones pendientes mediante los servicios de Windows Update, actualiza las definiciones de Microsoft Defender con `Update-MpSignature` y obtiene las actualizaciones de aplicaciones mediante `winget upgrade`.

La búsqueda y la instalación se ejecutan en procesos separados. Los resultados temporales se guardan en `%LOCALAPPDATA%\ActualizadorPC` para que la interfaz pueda mostrar el progreso.

## Seguridad y comportamiento

- No incluye ni solicita contraseñas, tokens o claves de API.
- No desinstala aplicaciones.
- No reinicia Windows automáticamente.
- Solo instala los elementos seleccionados por el usuario.
- Utiliza herramientas y servicios incluidos o administrados por Windows.

Antes de instalar una actualización, guarda tu trabajo y cierra las aplicaciones relacionadas. Algunas actualizaciones pueden requerir reiniciar el equipo.

## Solución de problemas

### `winget` no se reconoce

Instala o actualiza **App Installer** desde Microsoft Store y vuelve a abrir la aplicación.

### Una actualización queda como pendiente

Consulta el detalle mostrado en el registro. Cierra la aplicación afectada, comprueba tu conexión y vuelve a ejecutar la búsqueda. Algunos instaladores requieren intervención o permisos de administrador.

### Windows bloquea el script

Ejecuta siempre `Iniciar.cmd`, que inicia el script con la configuración necesaria para esa sesión. Descarga el proyecto únicamente desde este repositorio.

## Estructura del proyecto

```text
ActualizadorPC/
├── ActualizadorPC.ps1   # Aplicación e interfaz gráfica
├── Iniciar.cmd          # Inicio rápido
├── LEEME.txt            # Instrucciones breves
├── README.md            # Documentación principal
├── README.en.md         # Documentation in English
├── SECURITY.md          # Política de seguridad
├── SECURITY.en.md       # Security policy in English
├── CONTRIBUTING.md      # Guía para colaborar
├── CONTRIBUTING.en.md   # Contribution guide in English
└── LICENSE              # Licencia MIT
```

## Contribuciones

Las sugerencias y mejoras son bienvenidas. Consulta [CONTRIBUTING.md](CONTRIBUTING.md) antes de enviar cambios.

## Licencia

Este proyecto se distribuye bajo la [licencia MIT](LICENSE).
