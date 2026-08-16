# Compilación de BiteDJ para Ubuntu 24.04 ARM64

Desde la raíz del proyecto, en un equipo Ubuntu 24.04 ARM64, ejecuta:

```bash
bash ./tools/build-bitedj-arm64.sh
```

El script instala las dependencias de compilación, configura CMake en modo
Release y genera:

- `dist-arm64/bitedj-arm64/bin/bitedj`: ejecutable ARM64.
- `dist-arm64/bitedj-ubuntu-24.04-arm64.tar.gz`: paquete con el ejecutable,
  recursos, licencia y README.

Para instalarlo en el equipo destino:

```bash
tar -xzf bitedj-ubuntu-24.04-arm64.tar.gz
cd bitedj-arm64
./bin/bitedj --resourcePath "$PWD/res"
```

El binario se enlaza dinámicamente con las bibliotecas de Ubuntu 24.04, por lo
que el equipo destino debe tener instaladas las bibliotecas de ejecución de Qt6,
audio, FFmpeg y gráficos correspondientes.
