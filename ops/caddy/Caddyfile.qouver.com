# Caddyfile for qouver.com: host Caddy (VPS) → static file_server + reverse_proxy to qouver-api
#
# Uniform architecture with cbs.qouver.com and fond.qouver.com:
# - Frontend: static pre-rendered files at /srv/qouver/apps/qouver/web served by Caddy file_server
# - Backend API: container qouver-api at 127.0.0.1:8091
#
# Append this block to /etc/caddy/Caddyfile and reload:
# sudo caddy reload --config /etc/caddy/Caddyfile

qouver.com {
	log {
		import log_access
	}

	encode zstd gzip

	# Reverse proxy API & health checks to Nim backend
	handle /api/* {
		reverse_proxy 127.0.0.1:8091
	}
	handle /healthz {
		reverse_proxy 127.0.0.1:8091
	}

	# Static web files served directly by Caddy
	root * /srv/qouver/apps/qouver/web
	handle {
		try_files {path} {path}/index.html /index.html
		file_server
	}

	# Security headers
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options "nosniff"
		X-Frame-Options "DENY"
		Referrer-Policy "strict-origin-when-cross-origin"
		Permissions-Policy "camera=(), microphone=(), geolocation=()"
		Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://analytics.qouver.com; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:; connect-src 'self' https://analytics.qouver.com; base-uri 'self'; frame-ancestors 'none'; form-action 'self'"
	}

	# Caching
	header Cache-Control "no-cache"
}

www.qouver.com {
	redir https://qouver.com{uri} permanent
}
