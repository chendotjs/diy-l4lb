FROM ubuntu:22.04

RUN apt update

RUN apt -y install clang llvm libelf-dev libpcap-dev gcc-multilib build-essential make tcpdump git iproute2 curl linux-tools-common

WORKDIR /diy-l4lb-code

CMD [ "sleep", "infinity" ]