import ServiceManagement

/// Envoltorio sobre `SMAppService` (macOS 13+) para arrancar la app al
/// iniciar sesión.
///
/// Solo funciona de verdad cuando la app corre desde un `.app` empaquetado
/// en disco (vía `scripts/build-app.sh`) — bajo `swift run` falla en
/// silencio, ya que no hay un bundle real que registrar.
enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // No hay bundle válido (p.ej. `swift run` en desarrollo) o el
            // usuario denegó el registro — se ignora silenciosamente.
        }
    }
}
