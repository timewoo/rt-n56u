THISDIR = $(shell pwd)
# Xray-core 入口包(go modules)
xray_dir = "xray-core/main"
export GO111MODULE=on
export GOPROXY=https://proxy.golang.org,direct

# 目标版本:最新稳定版(支持 XTLS-Vision / Reality)。
# 如需升级,直接修改下面版本号即可(注意构建机 Go 版本需满足该版本要求,CI 用 setup-go stable)。
Xray_VERSION := 26.3.27
Xray_URL := https://codeload.github.com/XTLS/Xray-core/tar.gz/v$(Xray_VERSION)

all: download_xray build_extract build_xray

download_xray:
	( if [ ! -f $(THISDIR)/Xray-core-$(Xray_VERSION).tar.gz ]; then \
	curl --create-dirs -L $(Xray_URL) -o $(THISDIR)/Xray-core-$(Xray_VERSION).tar.gz ; \
	fi )

build_extract:
	mkdir -p $(THISDIR)/bin
	( if [ ! -d $(THISDIR)/xray-core ]; then \
	tar zxfv $(THISDIR)/Xray-core-$(Xray_VERSION).tar.gz -C $(THISDIR) ; \
	mv $(THISDIR)/Xray-core-$(Xray_VERSION) $(THISDIR)/xray-core ; \
	fi )

build_xray:
	( cd $(THISDIR)/xray-core; \
	GOOS=linux GOARCH=mipsle go build -trimpath -ldflags "-w -s -buildid=" -o $(THISDIR)/bin/xray ./main; \
	)

clean:
	rm -rf $(THISDIR)/xray-core
	rm -rf $(THISDIR)/bin

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/bin/xray /usr/bin/xray
