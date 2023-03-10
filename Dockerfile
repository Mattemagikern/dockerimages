FROM ubuntu:20.04

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install wget sudo

RUN wget https://apt.kitware.com/kitware-archive.sh && sudo bash kitware-archive.sh
RUN rm kitware-archive.sh

RUN apt-get install -y git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 \
  sudo locales screen

# Initialise system locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Python dependencies
RUN pip3 install wheel pip -U &&\
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt

# Install Zephyr SDK
RUN mkdir -p /opt/toolchains && cd /opt/toolchains 

RUN wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.15.2/zephyr-sdk-0.15.2_linux-x86_64.tar.gz 
RUN tar xvf zephyr-sdk-0.15.2_linux-x86_64.tar.gz -C /opt/toolchains/
RUN /opt/toolchains/zephyr-sdk-0.15.2/setup.sh -t all -h -c 
RUN rm zephyr-sdk-0.15.2_linux-x86_64.tar.gz 

# Set the locale

RUN wget https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-18-1/nrf-command-line-tools_10.18.1_amd64.deb 
RUN dpkg -i nrf-command-line-tools_10.18.1_amd64.deb 
RUN rm nrf-command-line-tools_10.18.1_amd64.deb 

RUN sudo apt-get -y install libxcb-render0 libxcb-render-util0 \
	libxcb-shape0 libxcb-icccm4 libxcb-keysyms1 libxcb-image0 libxkbcommon-x11-0 udev xxd git
COPY JLink_Linux_V782e_x86_64.tgz .
RUN mkdir /opt/SEGGER/ 
RUN tar -xvf JLink_Linux_V782e_x86_64.tgz -C /opt/SEGGER/
run ln -s /opt/SEGGER/JLink_Linux_V782e_x86_64 /opt/JLink
RUN rm JLink_Linux_V782e_x86_64.tgz
RUN echo "/opt/JLink/" > /etc/ld.so.conf.d/JLink.conf

COPY ./nrfutil /bin/nrfutil
RUN pip3 install robotframework==5.0.1

ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.15.2
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/JLink/
ENV PATH=$PATH:/opt/JLink/
RUN apt-get install bsdmainutils
RUN git config --global --add safe.directory '*'
