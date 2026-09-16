# ActualizadorPC

[Versión en español](README.md)

A graphical Windows 11 application that brings updates from the following sources together in one window:

- Windows Update
- Microsoft Defender
- Applications supported by `winget`

The user chooses which items to install. The application does not uninstall programs or restart the computer automatically.

## Features

- Simple graphical interface.
- Combined search for system, Defender, and application updates.
- Individual selection of items to install.
- Visible results for every operation.
- Notification when Windows requires a restart.
- Background processing to keep the interface responsive.

## Requirements

- Windows 11.
- Windows PowerShell 5.1.
- App Installer and `winget` available on the computer.
- An Internet connection.
- Administrator privileges when requested by Windows or an installer.

## Installation

1. Download the repository using **Code > Download ZIP**.
2. Extract the ZIP file to a folder of your choice.
3. Keep `Iniciar.cmd` and `ActualizadorPC.ps1` in the same folder.

You can also clone the project:

```powershell
git clone https://github.com/Jose199909/ActualizadorPC.git
```

## Usage

1. Double-click `Iniciar.cmd`.
2. Select **Buscar actualizaciones** to search for updates.
3. Check the items you want to install.
4. Select **Instalar seleccionadas**.
5. Review the results shown at the bottom of the window.

If Windows requests administrator privileges, review the prompt and approve it to continue with the corresponding update.

> The application interface is currently in Spanish. The button names above match the labels shown in the application.

## How it works

`ActualizadorPC.ps1` uses Windows Update services to find pending system updates, updates Microsoft Defender definitions with `Update-MpSignature`, and finds application updates through `winget upgrade`.

Scanning and installation run in separate processes. Temporary results are stored under `%LOCALAPPDATA%\ActualizadorPC` so the interface can display progress.

## Security and behavior

- Does not include or request passwords, tokens, or API keys.
- Does not uninstall applications.
- Does not restart Windows automatically.
- Installs only the items selected by the user.
- Uses tools and services included with or managed by Windows.

Save your work and close related applications before installing updates. Some updates may require a system restart.

## Troubleshooting

### `winget` is not recognized

Install or update **App Installer** from Microsoft Store, then reopen the application.

### An update remains pending

Check the details shown in the log. Close the affected application, verify your Internet connection, and run the scan again. Some installers require interaction or administrator privileges.

### Windows blocks the script

Always start the application with `Iniciar.cmd`, which launches the script with the required settings for that session. Download the project only from this repository.

## Project structure

```text
ActualizadorPC/
├── ActualizadorPC.ps1   # Application and graphical interface
├── Iniciar.cmd          # Quick launcher
├── LEEME.txt            # Short Spanish instructions
├── README.md            # Main Spanish documentation
├── README.en.md         # English documentation
├── SECURITY.md          # Spanish security policy
├── SECURITY.en.md       # English security policy
├── CONTRIBUTING.md      # Spanish contribution guide
├── CONTRIBUTING.en.md   # English contribution guide
└── LICENSE              # MIT License
```

## Contributing

Suggestions and improvements are welcome. Read [CONTRIBUTING.en.md](CONTRIBUTING.en.md) before submitting changes.

## License

This project is distributed under the [MIT License](LICENSE).

