
IMAGE = l4lb-demo:latest
MAC_PREFIX="12:34:56:78:9a"
IP_PREFIX="172.255.255"

BPF_TARGET = lb_kern
BPF_C = ${BPF_TARGET:=.c}
BPF_OBJ = ${BPF_C:.c=.o}

xdp: $(BPF_OBJ)
ifeq (${HOSTNAME},lb)
	ip link set eth0 xdpgeneric off
	ip link set eth0 xdpgeneric obj lb_kern.o sec xdp
else
	@echo "===> Can only execute in container, exit... <==="
endif

image:
	docker build -t $(IMAGE) .

setup-env: image teardown-env
	@echo "===> Creating docker bridge <==="
	docker network create --subnet=$(IP_PREFIX).0/24 lbnet

	@echo "===> Creating client container <==="
	docker run -d --rm --net=lbnet --ip=$(IP_PREFIX).3 --mac-address=$(MAC_PREFIX):03 --privileged -h client --name client -w /tmp --env TERM=xterm-color $(IMAGE)

	@echo "===> Creating lb container <==="
	docker run -d --rm --net=lbnet --ip=$(IP_PREFIX).4 --mac-address=$(MAC_PREFIX):04 --privileged -h lb --name lb --env TERM=xterm-color -v $(shell pwd):/diy-l4lb-code $(IMAGE)

	@echo "===> Creating backend containers <==="
	docker run -d --rm --net=lbnet --ip=$(IP_PREFIX).5 --mac-address=$(MAC_PREFIX):05 --name backend-A -h backend-A --env TERM=xterm-color nginxdemos/hello:plain-text
	docker run -d --rm --net=lbnet --ip=$(IP_PREFIX).6 --mac-address=$(MAC_PREFIX):06 --name backend-B -h backend-B --env TERM=xterm-color nginxdemos/hello:plain-text

teardown-env:
	@echo "===> Removming deprecated containers <==="
	docker rm -f client lb backend-A backend-B

	@echo "===> Removming deprecated bridge <==="
	docker network rm lbnet


$(BPF_OBJ): %.o: %.c
	clang -S \
	    -target bpf \
	    -Ilibbpf/src\
	    -Wall \
	    -Wno-unused-value \
	    -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -Werror \
	    -O2 -emit-llvm -c -o ${@:.o=.ll} $<
	llc -march=bpf -filetype=obj -o $@ ${@:.o=.ll}

clean:
	ip link set eth0 xdpgeneric off
	rm $(BPF_OBJ)
	rm ${BPF_OBJ:.o=.ll}