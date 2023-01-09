
IMAGE = l4lb-demo:latest
MAC_PREFIX="12:34:56:78:9a"
IP_PREFIX="172.255.255"

image:
	docker build -t $(IMAGE) .

setup-env: image teardown-env
	@echo "===> Creating docker bridge <==="
	docker network create --subnet=$(IP_PREFIX).0/24 lbnet

	@echo "===> Creating client container <==="
	docker run -d --rm --ip=$(IP_PREFIX).3 --mac-address=$(MAC_PREFIX):03 --privileged -h client --name client --env TERM=xterm-color $(IMAGE)

	@echo "===> Creating lb container <==="
	docker run -d --rm --ip=$(IP_PREFIX).4 --mac-address=$(MAC_PREFIX):04 --privileged -h lb --name lb --env TERM=xterm-color $(IMAGE)

	@echo "===> Creating backend containers <==="
	docker run -d --rm --ip=$(IP_PREFIX).5 --mac-address=$(MAC_PREFIX):05 --name backend-A -h backend-A --env TERM=xterm-color nginxdemos/hello:plain-text
	docker run -d --rm --ip=$(IP_PREFIX).6 --mac-address=$(MAC_PREFIX):06 --name backend-B -h backend-B --env TERM=xterm-color nginxdemos/hello:plain-text

teardown-env:
	@echo "===> Removming deprecated containers <==="
	docker rm -f client lb backend-A backend-B

	@echo "===> Removming deprecated bridge <==="
	docker network rm lbnet

xdp:

clean: