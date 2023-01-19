# from https://github.com/realies/audiowaveform-docker/blob/master/Dockerfile

FROM ruby:2.7.5-alpine as audiowaveform-builder

RUN apk add --no-cache boost-dev boost-static cmake curl g++ gcc gd-dev git \
    jq libid3tag-dev libmad-dev libpng-static libsndfile-dev libvorbis-static make zlib-static

RUN apk add --no-cache autoconf automake libtool gettext && \
    curl -fL# "$(curl -s 'https://api.github.com/repos/xiph/flac/tags' | jq -r '. | first | .tarball_url')" -o flac.tar.gz && \
    mkdir flac && \
    tar -xf flac.tar.gz -C flac --strip-components=1 && \
    cd flac && \
    ./autogen.sh && \
    ./configure --enable-shared=no && \
    make -j $(nproc) && \
    make install

RUN git clone -n https://github.com/bbc/audiowaveform.git && \
    cd audiowaveform && \
    git checkout ${COMMIT} && \
    curl -fL# "$(curl -s 'https://api.github.com/repos/google/googletest/releases/latest' | jq -r '.tarball_url')" -o googletest.tar.gz && \
    mkdir googletest && \
    tar -xf googletest.tar.gz -C googletest --strip-components=1 && \
    mkdir build && \
    cd build && \
    cmake -D ENABLE_TESTS=0 -D BUILD_STATIC=1 .. && \
    make -j $(nproc) && \
    make install && \
    strip /usr/local/bin/audiowaveform


# copy ffmbc shared dependencies to /tmp/fakeroot
ENV SHARED_DIR=/tmp/fakeroot
ENV PREFIX=/usr/local

RUN mkdir -p ${SHARED_DIR}/lib
RUN ldd ${PREFIX}/bin/audiowaveform | cut -d ' ' -f 3 | strings | xargs -I R cp R ${SHARED_DIR}/lib/
# RUN for lib in ${SHARED_DIR}/lib/*; do strip --strip-all $lib; done
RUN cp -r ${PREFIX}/bin ${SHARED_DIR}/bin/
RUN cp -r ${PREFIX}/share ${SHARED_DIR}/share/
RUN cp -r ${PREFIX}/include ${SHARED_DIR}/include
