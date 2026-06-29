#!/bin/bash

# Script para crear proyecto Xcode LEDCarControl automáticamente
# Ejecutar en Mac: bash create_xcode_project.sh

set -e

PROJECT_NAME="LEDCarControl"
BUNDLE_ID="com.ledcar.control"

echo "📦 Creando proyecto Xcode: $PROJECT_NAME"

# Crear directorio principal
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Crear estructura de carpetas
mkdir -p "$PROJECT_NAME"
mkdir -p "${PROJECT_NAME}Widget"

echo "✓ Estructura de carpetas creada"

# Los archivos Swift se deben copiar en las carpetas:
# LEDCarControl/LEDCarControl/LEDCarAppCompleta.swift
# LEDCarControl/LEDCarControlWidget/LEDCarWidget.swift
# LEDCarControl/Info.plist

echo ""
echo "=========================================="
echo "✅ PROYECTO LISTO PARA CONFIGURAR EN XCODE"
echo "=========================================="
echo ""
echo "INSTRUCCIONES:"
echo ""
echo "1. Abre Xcode"
echo "2. File → New → Project"
echo "3. iOS → App"
echo "4. Product Name: LEDCarControl"
echo "5. Team: (selecciona tu team)"
echo "6. Language: Swift"
echo "7. Interface: SwiftUI"
echo "8. Presiona CREATE"
echo ""
echo "9. COPIA ARCHIVOS:"
echo "   - LEDCarAppCompleta.swift → proyecto/LEDCarControl/ContentView.swift"
echo "   - LEDCarWidget.swift → proyecto/LEDCarControlWidget/LEDCarWidget.swift"
echo ""
echo "10. Info.plist: Agrega 4 permisos Bluetooth"
echo ""
echo "11. Product → Run (Cmd+R)"
echo ""
echo "=========================================="
