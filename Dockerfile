FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential nasm cmake git curl ca-certificates \
    libgmp-dev libssl-dev wget unzip pkg-config nodejs npm libgtest-dev && \
    rm -rf /var/lib/apt/lists/*

RUN cmake -S /usr/src/googletest/googletest -B /tmp/gtest -DCMAKE_POSITION_INDEPENDENT_CODE=ON && \
    cmake --build /tmp/gtest && \
    cp /tmp/gtest/lib/*.a /usr/lib/

WORKDIR /work

RUN npm i -g ffiasm
RUN buildzqfield -q 21888242871839275222246405745257275088548364400416034343698204186575808495617 -n Fr
RUN buildzqfield -q 21888242871839275222246405745257275088548364400416034343698204186575808495617 -n Fq

RUN git clone --depth 1 https://github.com/iden3/ffiasm.git
RUN cp ffiasm/c/alt_bn128_test.cpp .

RUN nasm -felf64 fr.asm -o fr.o && \
    nasm -felf64 fq.asm -o fq.o && \
    g++ -std=c++17 -O3 -I . -I ffiasm/c \
       fr.o fr.cpp fq.o fq.cpp \
       ffiasm/c/alt_bn128.cpp ffiasm/c/naf.cpp ffiasm/c/splitparstr.cpp ffiasm/c/misc.cpp \
       alt_bn128_test.cpp \
       /usr/lib/libgtest.a -pthread -lgmp \
       -o alt_bn128_test

RUN ls -lah /work && stat /work/alt_bn128_test && chmod +x /work/alt_bn128_test

CMD ["/work/alt_bn128_test","--gtest_color=yes"]
