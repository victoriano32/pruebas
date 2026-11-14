// Disposición "Barra superior + dock": barra fina arriba y dock flotante abajo.
var barra = new Panel;
barra.location = "top";
barra.height = Math.round(gridUnit * 1.75);
try { barra.lengthMode = "fill"; } catch (e) {}
try { barra.floating = false; } catch (e) {}

var menu = barra.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "@ICONO_MENU@");

barra.addWidget("org.kde.plasma.appmenu");
barra.addWidget("org.kde.plasma.panelspacer");
barra.addWidget("org.kde.plasma.digitalclock");
barra.addWidget("org.kde.plasma.panelspacer");
barra.addWidget("org.kde.plasma.systemtray");

var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3);
try { dock.alignment = "center"; } catch (e) {}
try { dock.lengthMode = "fit"; } catch (e) {}
try { dock.floating = true; } catch (e) {}
try { dock.hiding = "dodgewindows"; } catch (e) {}

var tareas = dock.addWidget("org.kde.plasma.icontasks");
tareas.currentConfigGroup = ["General"];
tareas.writeConfig("launchers", [
    "preferred://browser",
    "preferred://filemanager",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop",
    "applications:brisa-personalizar.desktop"
]);
