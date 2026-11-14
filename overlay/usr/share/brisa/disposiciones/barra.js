// Disposición "Barra": una barra flotante abajo que ocupa todo el ancho.
var panel = new Panel;
panel.location = "bottom";
panel.height = Math.round(gridUnit * 2.5);
try { panel.lengthMode = "fill"; } catch (e) {}
try { panel.floating = true; } catch (e) {}
try { panel.hiding = "none"; } catch (e) {}

var menu = panel.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "@ICONO_MENU@");

var tareas = panel.addWidget("org.kde.plasma.icontasks");
tareas.currentConfigGroup = ["General"];
tareas.writeConfig("launchers", [
    "preferred://browser",
    "preferred://filemanager",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop",
    "applications:brisa-personalizar.desktop"
]);

panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");
