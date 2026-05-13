

---

## 1. Lanzar el Asistente Visual
Ejecuta este comando para abrir la ventana de configuración. Es **obligatorio** completarlo para que aparezca la carpeta `~/Android/Sdk`:

```bash
sh ~/android-studio/bin/studio.sh
```

---

## 2. Pasos dentro de Android Studio
No cierres la ventana hasta que llegues al final de estos tres puntos:

1.  **Import Settings:** Elige "Do not import settings".
2.  **Setup Wizard:** Elige la instalación **"Standard"**. Esto descargará los componentes necesarios (unos 1.2 GB).
3.  **Verify Settings:** Te mostrará una lista. Dale a **"Next"**.
4.  **License Agreement:** Este es el truco. A la izquierda verás varios nombres (android-sdk-license, arm-dbt-license, etc.). Haz clic en **cada uno** y marca el botón **"Accept"**. Solo cuando todos tengan el punto de aceptación se habilitará el botón **"Finish"**.

---

## 3. El Toque Final (Command-line Tools)
Una vez que termine la descarga y estés en la pantalla de "Welcome to Android Studio":

1. Haz clic en **More Actions** (abajo a la derecha) > **SDK Manager**.
2. Ve a la pestaña **SDK Tools**.
3. Busca **"Android SDK Command-line Tools (latest)"**, márcala y dale a **Apply**.

---

## 4. Conectar con Flutter
Cuando cierres Android Studio, vuelve a tu terminal y "pasa el cerrojo" con estos comandos:

```bash
# 1. Vincular la ruta
flutter config --android-sdk ~/Android/Sdk

# 2. Aceptar licencias en la terminal
flutter doctor --android-licenses
```

> **Dato de Senior:** Si `flutter doctor --android-licenses` te dice que no encuentra el `sdkmanager`, asegúrate de haber hecho el **Paso 3** (las Command-line Tools). Es el error más común en este punto.

---

<FollowUp label="¿Ya terminaste la descarga? Verifiquemos si flutter doctor ya está en verde." query="Ejecuta flutter doctor y dime si el apartado de Android ya tiene el check verde para empezar con el código de Flutter." />