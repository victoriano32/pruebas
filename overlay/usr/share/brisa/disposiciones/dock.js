// Disposición "Dock": un panel flotante centrado abajo, ajustado a su contenido.
var panel = new Panel;
panel.location = "bottom";
panel.height = Math.round(gridUnit * 2.75);
try { panel.alignment = "center"; } catch (e) {}
try { panel.lengthMode = "fit"; } catch (e) {}
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

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
