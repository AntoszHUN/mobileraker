> The FAQ is still WIP

## 🚀 What is Mobileraker?
🏷️ Mobileraker works as a simple UI for Klipper on the phone. Connect it to an existing moonraker installation and control the printer.

## 📷 How do I add a WebCam ?
Out of the box, Mobileraker offers support for any MJPEG webcam streams directly on the dashboard screen. You can add as many webcams as you like on the printer's setting page. To open it, open the navigation bar and press the gear icon at the top, right next to your printer's name. This opens the printer's settings. Scroll down until you reach the webcam section. After you are done adding/editing a webcam please make sure you press save.

## 🛰️ Remote printer access?
There exist multiple options to access your printer from everywhere. Among these options are:
- VPN
- [Octoeverywhere](https://octoeverywhere.com/)
>The fastest, easiest, and suggested option is Octoeverywhere.

## 📫 How to setup Push Notifications?
Mobileraker supports native push notifications for both Android and iOS. In order to setup it you will need to execute the following commands on your RaspberryPI/Linux OS:

```shell
cd ~/
git clone https://github.com/Clon1998/mobileraker_companion.git
cd mobileraker_companion
./scripts/install-mobileraker-companion.sh
```

Find out more at the official GitHub page of [mobileraker_companion](https://github.com/Clon1998/mobileraker_companion).

