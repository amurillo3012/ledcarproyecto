import SwiftUI
import CoreBluetooth
import MapKit

// MARK: - Main App Entry Point
@main
struct LEDCarControlApp: App {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bluetoothManager)
        }
    }
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false
    @Published var discoveredDevices: [BLEDevice] = []
    @Published var connectedDevice: BLEDevice?
    @Published var connectionStatus = "Desconectado"
    @Published var statusColor: Color = .gray
    
    private var centralManager: CBCentralManager?
    private var writeCharacteristic: CBCharacteristic?
    
    // BLE UUIDs para LED CAR 01
    private let serviceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    private let writeCharacteristicUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    private let readCharacteristicUUID = CBUUID(string: "0000FFE2-0000-1000-8000-00805F9B34FB")
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Scanning
    func startScanning() {
        guard let central = centralManager, central.state == .poweredOn else {
            connectionStatus = "Bluetooth no disponible"
            statusColor = .red
            return
        }
        
        isScanning = true
        discoveredDevices.removeAll()
        connectionStatus = "Buscando dispositivos..."
        statusColor = .orange
        
        central.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }
    
    func connect(to device: BLEDevice) {
        guard let central = centralManager else { return }
        connectionStatus = "Conectando..."
        statusColor = .yellow
        central.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        if let device = connectedDevice {
            centralManager?.cancelPeripheralConnection(device.peripheral)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth activado"
            statusColor = .blue
        case .poweredOff:
            connectionStatus = "Bluetooth desactivado"
            statusColor = .red
        case .unauthorized:
            connectionStatus = "Acceso Bluetooth denegado"
            statusColor = .red
        default:
            connectionStatus = "Estado desconocido"
            statusColor = .gray
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? "Desconocido"
        
        // Filtrar solo dispositivos LED CAR
        guard deviceName.contains("LED CAR") || deviceName.contains("LED") else { return }
        
        // Evitar duplicados
        if !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            let device = BLEDevice(
                id: peripheral.identifier,
                name: deviceName,
                peripheral: peripheral,
                rssi: RSSI.intValue
            )
            DispatchQueue.main.async {
                self.discoveredDevices.append(device)
                self.discoveredDevices.sort { $0.rssi > $1.rssi }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        
        if let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.connectedDevice = device
                self.connectionStatus = "Conectado: \(device.name)"
                self.statusColor = .green
                self.isScanning = false
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = "Error de conexión"
            self.statusColor = .red
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectedDevice = nil
            self.connectionStatus = "Desconectado"
            self.statusColor = .gray
            self.writeCharacteristic = nil
        }
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([writeCharacteristicUUID, readCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == writeCharacteristicUUID {
                writeCharacteristic = characteristic
                DispatchQueue.main.async {
                    self.connectionStatus = "Listo para enviar comandos"
                }
            }
        }
    }
    
    // MARK: - LED Commands
    func sendCommand(_ bytes: [UInt8]) {
        guard let device = connectedDevice, let characteristic = writeCharacteristic else { return }
        let data = Data(bytes)
        device.peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func setColor(r: UInt8, g: UInt8, b: UInt8) {
        let command: [UInt8] = [0x7e, 0x00, 0x05, 0x03, r, g, b, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setBrightness(_ brightness: UInt8) {
        let value = min(brightness, 100)
        let command: [UInt8] = [0x7e, 0x00, 0x01, value, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setEffect(_ effectCode: UInt8) {
        let command: [UInt8] = [0x7e, 0x00, 0x03, effectCode, 0x03, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setEffectSpeed(_ speed: UInt8) {
        let value = min(speed, 100)
        let command: [UInt8] = [0x7e, 0x00, 0x02, value, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setPower(on: Bool) {
        let value: UInt8 = on ? 0x01 : 0x00
        let command: [UInt8] = [0x7e, 0x00, 0x04, value, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
}

// MARK: - Models
struct BLEDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    let rssi: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedTab = 0
    @State private var showConnectionDetails = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(#colorLiteral(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)),
                    Color(#colorLiteral(red: 0.12, green: 0.08, blue: 0.15, alpha: 1))
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    connectionStatus: bluetoothManager.connectionStatus,
                    statusColor: bluetoothManager.statusColor,
                    isConnected: bluetoothManager.connectedDevice != nil
                )
                
                if bluetoothManager.connectedDevice == nil {
                    // Connection Screen
                    DeviceScannerView()
                } else {
                    // Main Control Tabs
                    TabView(selection: $selectedTab) {
                        ColorControlView()
                            .tag(0)
                        
                        EffectsView()
                            .tag(1)
                        
                        CarVisualizationView()
                            .tag(2)
                        
                        NavigationModeView()
                            .tag(3)
                        
                        AutomationsView()
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Tab Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(index == selectedTab ? Color.cyan : Color.white.opacity(0.2))
                                .frame(height: 4)
                                .onTapGesture { selectedTab = index }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let connectionStatus: String
    let statusColor: Color
    let isConnected: Bool
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LED CAR 01")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(connectionStatus)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if isConnected {
                    Button(action: { bluetoothManager.disconnect() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
        }
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Device Scanner View
struct DeviceScannerView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(spacing: 20) {
            if bluetoothManager.isScanning {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.cyan)
                    Text("Buscando dispositivos...")
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
            }
            
            if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No se encontraron dispositivos")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Asegúrate de que las luces estén encendidas")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            DeviceRow(device: device)
                                .onTapGesture {
                                    bluetoothManager.stopScanning()
                                    bluetoothManager.connect(to: device)
                                }
                        }
                    }
                    .padding(20)
                }
            }
            
            Button(action: {
                if bluetoothManager.isScanning {
                    bluetoothManager.stopScanning()
                } else {
                    bluetoothManager.startScanning()
                }
            }) {
                HStack {
                    Image(systemName: bluetoothManager.isScanning ? "stop.circle.fill" : "magnifyingglass")
                    Text(bluetoothManager.isScanning ? "Detener búsqueda" : "Buscar dispositivos")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(bluetoothManager.isScanning ? Color.red : Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .semibold))
            }
            .padding(20)
        }
    }
}

struct DeviceRow: View {
    let device: BLEDevice
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(device.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                    
                    Text("\(device.rssi) dBm")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Color Control View
struct ColorControlView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedColor = Color.cyan
    @State private var brightness: Double = 100
    @State private var showColorPicker = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Color Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                selectedColor.opacity(0.3),
                                selectedColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                
                VStack(spacing: 10) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedColor)
                    
                    Text("Seleccionar Color")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(height: 280)
            .padding(.horizontal, 30)
            .onTapGesture { showColorPicker = true }
            
            // Brightness Slider
            VStack(spacing: 12) {
                HStack {
                    Text("Brillo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(brightness))%")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $brightness, in: 0...100)
                    .onChange(of: brightness) { value in
                        bluetoothManager.setBrightness(UInt8(value))
                    }
                    .tint(.cyan)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $selectedColor, bluetoothManager: bluetoothManager)
        }
    }
}

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    let bluetoothManager: BluetoothManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Seleccionar Color")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ColorPicker("", selection: $selectedColor)
                .frame(height: 300)
            
            Button(action: {
                let components = UIColor(selectedColor).cgColor.components ?? [1, 0, 0, 1]
                let r = UInt8(components[0] * 255)
                let g = UInt8(components[1] * 255)
                let b = UInt8(components[2] * 255)
                
                bluetoothManager.setColor(r: r, g: g, b: b)
                dismiss()
            }) {
                Text("Aplicar")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(#colorLiteral(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)))
    }
}

// MARK: - Effects View
struct EffectsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var effectSpeed: Double = 50
    
    let effects: [(name: String, code: UInt8)] = [
        ("Rojo", 0x80),
        ("Verde", 0x81),
        ("Azul", 0x82),
        ("Amarillo", 0x83),
        ("Cian", 0x84),
        ("Magenta", 0x85),
        ("Blanco", 0x86),
        ("Jump RGB", 0x87),
        ("Gradient RGB", 0x89),
        ("Blink Arcoíris", 0x95),
        ("Breathing Arcoíris", 0xA5),
        ("Onda RGB", 0xA6),
        ("Persecución", 0xA7),
        ("Fuego", 0xAF),
        ("Policía", 0xB0),
        ("Ambulancia", 0xB1),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Text("Velocidad")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(effectSpeed))")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $effectSpeed, in: 0...100)
                    .onChange(of: effectSpeed) { value in
                        bluetoothManager.setEffectSpeed(UInt8(value))
                    }
                    .tint(.cyan)
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(effects, id: \.code) { effect in
                        Button(action: {
                            bluetoothManager.setEffect(effect.code)
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                Text(effect.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.cyan)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Car Visualization View
struct CarVisualizationView: View {
    @State private var selectedZone: CarZone? = nil
    
    enum CarZone {
        case tablero
        case puerDerDel
        case puerIzqDel
        case puerDerTra
        case puerIzqTra
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Control por Zonas")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ZStack {
                // Auto 2D
                Canvas { context in
                    drawCar(in: context)
                }
                .frame(height: 400)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Información")
                        .foregroundColor(.white)
                    Spacer()
                    Text("Las zonas se controlan juntas (maestro)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    private func drawCar(in context: GraphicsContext) {
        var path = Path()
        
        // Tablero (rectangulo superior)
        path.addRoundedRect(in: CGRect(x: 50, y: 50, width: 300, height: 80), cornerSize: CGSize(width: 10, height: 10))
        context.fill(path, with: .color(.cyan.opacity(0.3)))
        context.stroke(path, with: .color(.cyan), lineWidth: 2)
        
        context.drawLayer { ctx in
            var textPath = Path()
            textPath.addRect(CGRect(x: 50, y: 50, width: 300, height: 80))
            
            var textContext = context
            textContext.fill(textPath, with: .color(.clear))
        }
        
        // Puertas
        let doorWidth: CGFloat = 60
        let doorHeight: CGFloat = 100
        
        // Puerta Izq Delantera
        var puerIzqDel = Path(roundedRect: CGRect(x: 20, y: 160, width: doorWidth, height: doorHeight), cornerRadius: 5)
        context.fill(puerIzqDel, with: .color(.white.opacity(0.1)))
        context.stroke(puerIzqDel, with: .color(.white.opacity(0.5)), lineWidth: 1.5)
        
        // Puerta Der Delantera
        var puerDerDel = Path(roundedRect: CGRect(x: 320, y: 160, width: doorWidth, height: doorHeight), cornerRadius: 5)
        context.fill(puerDerDel, with: .color(.white.opacity(0.1)))
        context.stroke(puerDerDel, with: .color(.white.opacity(0.5)), lineWidth: 1.5)
        
        // Puerta Izq Trasera
        var puerIzqTra = Path(roundedRect: CGRect(x: 20, y: 270, width: doorWidth, height: doorHeight), cornerRadius: 5)
        context.fill(puerIzqTra, with: .color(.white.opacity(0.1)))
        context.stroke(puerIzqTra, with: .color(.white.opacity(0.5)), lineWidth: 1.5)
        
        // Puerta Der Trasera
        var puerDerTra = Path(roundedRect: CGRect(x: 320, y: 270, width: doorWidth, height: doorHeight), cornerRadius: 5)
        context.fill(puerDerTra, with: .color(.white.opacity(0.1)))
        context.stroke(puerDerTra, with: .color(.white.opacity(0.5)), lineWidth: 1.5)
    }
}

// MARK: - Navigation Mode View
struct NavigationModeView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var navigationActive = false
    @State private var turnColor: Color = .white
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Modo Navegación")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Sincroniza los giros del navegador con los colores LED")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(navigationActive ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(navigationActive ? "Activo" : "Inactivo")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack {
                    Text("Color para giro")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Circle()
                        .fill(turnColor)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                Button(action: { navigationActive.toggle() }) {
                    HStack {
                        Image(systemName: navigationActive ? "pause.circle.fill" : "play.circle.fill")
                        Text(navigationActive ? "Desactivar" : "Activar modo navegación")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(navigationActive ? Color.red : Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .semibold))
                }
                
                HStack(spacing: 8) {
                    ForEach([Color.red, Color.green, Color.blue, Color.yellow], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .onTapGesture {
                                let components = UIColor(color).cgColor.components ?? [1, 0, 0, 1]
                                let r = UInt8(components[0] * 255)
                                let g = UInt8(components[1] * 255)
                                let b = UInt8(components[2] * 255)
                                
                                bluetoothManager.setColor(r: r, g: g, b: b)
                                turnColor = color
                            }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Automations View
struct AutomationsView: View {
    @State private var automations: [Automation] = []
    @State private var showAddAutomation = false
    
    struct Automation: Identifiable {
        let id = UUID()
        let name: String
        let time: String
        let action: String
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Automatizaciones")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showAddAutomation = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 10) {
                    if automations.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Sin automatizaciones")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(automations) { automation in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(automation.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(automation.time)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Text(automation.action)
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.cyan.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    ContentView()
        .environmentObject(BluetoothManager())
}
