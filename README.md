# Instruções em geral

## Compilar
A source utilizada do cliente foi a versão vazada (https://github.com/Stephany-The-Josh-Wife/otcv8-The-Josh-Wife-Edition) e os erros que impediam de compilá-la foram corrigidos. É necessário baixar as libs que se encontram em `otcv8-joshwife\lib` e jogar os arquivos em `C:\dev\otcv8-libs`. Lembre-se de utilizar o vcpkg e instalar a seguinte linha de comando:

```
vcpkg install boost-iostreams:x86-windows-static boost-asio:x86-windows-static boost-beast:x86-windows-static boost-system:x86-windows-static boost-variant:x86-windows-static boost-lockfree:x86-windows-static boost-process:x86-windows-static boost-program-options:x86-windows-static luajit:x86-windows-static glew:x86-windows-static boost-filesystem:x86-windows-static boost-uuid:x86-windows-static physfs:x86-windows-static openal-soft:x86-windows-static libogg:x86-windows-static libvorbis:x86-windows-static zlib:x86-windows-static libzip:x86-windows-static openssl:x86-windows-static
```

## Modo de Desenvolvimento
Caso o game vá para modo de produção, isto é, para os jogadores em si, vá em init.lua e desative a variável `DEVLOPMENT_MODE = false`.