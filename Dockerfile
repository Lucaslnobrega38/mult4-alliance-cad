FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# O pacote 'alliance' amd64 do Ubuntu 18.04 tem um asimut (simulador) quebrado:
# qualquer netlist estrutural com instanciacao de componente (Component/port map)
# causa SIGSEGV no binario 64-bit. Bug documentado/conhecido; a correcao e usar
# o build i386 (32-bit), que funciona corretamente em sistemas 64-bit.
# alliance e alliance:i386 se declaram Conflicts entre si (mesmos caminhos de
# arquivo), entao instalamos so a variante i386 -- nao as duas juntas.
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        alliance:i386 \
        build-essential \
        gcc-multilib \
        libc6-dev-i386 \
        man-db \
        vim \
        && \
    rm -rf /var/lib/apt/lists/*

ENV ALLIANCE_TOP=/usr
# ".:" primeiro para achar arquivos no diretorio de trabalho; sxlib explicito
# porque os componentes usados (a2_x2, xr2_x1, o2_x2, buf_x2) vivem la, nao
# diretamente em /usr/share/alliance/cells.
ENV MBK_CATA_LIB=".:/usr/share/alliance/cells/sxlib"
ENV MBK_IN_LO=vst
ENV MBK_OUT_LO=vst
ENV LD_LIBRARY_PATH=/usr/lib/alliance:${LD_LIBRARY_PATH}
ENV PATH=/usr/bin:${PATH}
# As libs Alliance instaladas (alliance:i386) sao 32-bit; o gcc do sistema
# gera 64-bit por padrao. genlib/boog/etc compilam e linkam codigo C do
# usuario contra essas libs, entao o build precisa ser 32-bit tambem.
ENV CFLAGS=-m32
ENV OFLAGS=-m32

WORKDIR /work

CMD ["/bin/bash"]
