FROM ubuntu:16.04

##### Windninja

RUN apt-get update && apt-get install -y cmake git build-essential sudo wget libfontconfig1-dev libcurl4-gnutls-dev libnetcdf-dev  libboost-program-options-dev libboost-date-time-dev libgeos-dev libboost-test-dev
# RUN apt-get install -y qt4-dev-tools libqtwebkit-dev  # only needed for windninja gui

ENV PREFIX /usr/local
ENV POPPLER "poppler-0.23.4"
ENV PROJ "proj-4.8.0"
ENV GDAL "gdal-2.0.3"

RUN mkdir /root/src
WORKDIR /root/src

## Get and build poppler for PDF support in GDAL
RUN wget http://poppler.freedesktop.org/$POPPLER.tar.xz &&\
    tar -xvf $POPPLER.tar.xz
WORKDIR $POPPLER/
RUN ./configure --prefix=$PREFIX --enable-xpdf-headers &&\
    make install -j8 &&\
    make clean


## Get and build proj
WORKDIR /root/src
RUN wget http://download.osgeo.org/proj/$PROJ.tar.gz &&\
    tar xvfz $PROJ.tar.gz
WORKDIR $PROJ
RUN ./configure --prefix=$PREFIX &&\
    make install -j8 &&\
    make clean
RUN cp $PREFIX/include/proj_api.h $PREFIX/lib


## Get and build GDAL with poppler support
WORKDIR /root/src
RUN wget http://download.osgeo.org/gdal/2.0.3/$GDAL.tar.gz &&\
    tar -xvf $GDAL.tar.gz
WORKDIR $GDAL/
RUN ./configure --prefix=$PREFIX --with-poppler=$PREFIX &&\
    make -j8 &&\
    make install &&\
    make clean

# create a local user
RUN useradd -ms /bin/bash windninja
USER windninja
WORKDIR /home/windninja

## Clone and build windninja client
RUN git clone --depth 1 https://github.com/firelab/windninja.git /home/windninja/windninja
RUN mkdir /home/windninja/windninja/build &&\
    cd /home/windninja/windninja/build &&\
    cmake -DNINJA_CLI=ON -DNINJAFOAM=ON -DNINJA_QTGUI=OFF .. &&\
    make -j8


USER root
# install to /usr/local/bin
RUN cd /home/windninja/windninja/build && make install

# Clean up
RUN rm -rf /home/windninja/windninja
RUN rm -rf /root/src
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*


# Set root password to "root"
RUN echo "root:root" | chpasswd
