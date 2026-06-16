local cjson = require "cjson"
local server_section = arg[1]
local proto = arg[2]
local local_port = arg[3] or "0"
local socks_port = arg[4] or "0"
local ssrindext = io.popen("dbus get ssconf_basic_json_" .. server_section)
local servertmp = ssrindext:read("*all")
local server = cjson.decode(servertmp)

-- 传输方式(network)
local network = server.xray_transport or "tcp"
-- 安全层:tls / reality / none
local security = server.xray_security or "none"
-- XTLS 流控(如 xtls-rprx-vision),为空则普通 TLS/无流控
local flow = (server.xray_flow ~= nil and server.xray_flow ~= "") and server.xray_flow or nil

local stream = {
	network = network,
	security = security
}

-- TLS 设置
if security == "tls" then
	stream.tlsSettings = {
		serverName = server.xray_sni,
		allowInsecure = (server.xray_insecure ~= nil and server.xray_insecure ~= "0") and true or false,
		fingerprint = (server.xray_fingerprint ~= nil and server.xray_fingerprint ~= "") and server.xray_fingerprint or nil,
		alpn = (server.xray_alpn ~= nil and server.xray_alpn ~= "") and { server.xray_alpn } or nil
	}
-- Reality 设置(免证书)
elseif security == "reality" then
	stream.realitySettings = {
		serverName = server.xray_sni,
		fingerprint = (server.xray_fingerprint ~= nil and server.xray_fingerprint ~= "") and server.xray_fingerprint or "chrome",
		publicKey = server.xray_pbk,
		shortId = server.xray_sid or "",
		spiderX = server.xray_spx or "/"
	}
end

-- 各 network 的传输细节
if network == "tcp" then
	stream.tcpSettings = {
		header = { type = "none" }
	}
elseif network == "ws" then
	stream.wsSettings = {
		path = server.xray_ws_path or "/",
		headers = (server.xray_ws_host ~= nil and server.xray_ws_host ~= "") and { Host = server.xray_ws_host } or nil
	}
elseif network == "grpc" then
	stream.grpcSettings = {
		serviceName = server.xray_grpc_service or ""
	}
elseif network == "h2" then
	stream.httpSettings = {
		path = server.xray_h2_path or "/",
		host = (server.xray_h2_host ~= nil and server.xray_h2_host ~= "") and { server.xray_h2_host } or nil
	}
end

local xray = {
	log = {
		loglevel = "warning"
	},
	-- 传入连接(透明代理)
	inbound = (local_port ~= "0") and {
		port = local_port,
		protocol = "dokodemo-door",
		settings = {
			network = proto,
			followRedirect = true
		},
		sniffing = {
			enabled = true,
			destOverride = { "http", "tls" }
		}
	} or nil,
	-- 开启 socks 代理
	inboundDetour = (proto == "tcp" and socks_port ~= "0") and {
		{
			protocol = "socks",
			port = socks_port,
			settings = {
				auth = "noauth",
				udp = true
			}
		}
	} or nil,
	-- 传出连接(VLESS + XTLS)
	outbound = {
		protocol = "vless",
		settings = {
			vnext = {
				{
					address = server.server,
					port = tonumber(server.server_port),
					users = {
						{
							id = server.xray_id or server.vmess_id,
							flow = flow,
							encryption = "none"
						}
					}
				}
			}
		},
		streamSettings = stream
	},
	-- 额外传出连接
	outboundDetour = {
		{
			protocol = "freedom",
			tag = "direct",
			settings = { keep = "" }
		}
	}
}

print(cjson.encode(xray))
