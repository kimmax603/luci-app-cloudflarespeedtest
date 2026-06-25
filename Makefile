include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-cloudflarespeedtest

LUCI_TITLE:=LuCI support for Cloudflare Speed Test with DNS Update
LUCI_DEPENDS:=+openssl-util +curl +ca-bundle
LUCI_PKGARCH:=all
PKG_VERSION:=2.0.0
PKG_RELEASE:=1
PKG_LICENSE:=AGPL-3.0

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
