
// Fondo de pantalla de la distro en todos los escritorios.
var escritorios = desktopsForActivity(currentActivity());
for (var i = 0; i < escritorios.length; i++) {
    escritorios[i].wallpaperPlugin = "org.kde.image";
    escritorios[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    escritorios[i].writeConfig("Image", "file:///usr/share/wallpapers/Brisa/");
}
