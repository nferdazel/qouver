# Caddyfile for qouver.com: host Caddy (VPS) → static file_server + reverse_proxy to qouver-api
#
# Uniform architecture with cbs.qouver.com and fond.qouver.com:
# - Frontend: static pre-rendered files at /srv/qouver/apps/qouver/web served by Caddy file_server
# - Backend API: container qouver-api at 127.0.0.1:8091
#
# Append this block to /etc/caddy/Caddyfile, validate, then restart:
# sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
# sudo systemctl restart caddy
# Reload does not work on the host: the global block sets `admin off`.

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
	#
	# adapter-static writes prerendered routes as <route>.html (projects.html,
	# projects/skyward.html), never <route>/index.html, so {path}.html must be
	# tried before the directory index. Without it every deep link falls through
	# to the last candidate and renders the home page with a 200.
	#
	# The trailing /index.html fallback is deliberately absent: it is what made
	# unknown URLs return the home page with status 200. Unknown paths now reach
	# handle_errors and get 404.html with a real 404.
	root * /srv/qouver/apps/qouver/web
	handle {
		try_files {path} {path}.html {path}/index.html
		file_server
	}
	# The imported header block below is deferred and does not reach the error
	# route, so the five security headers are repeated here. CSP still applies
	# from the block below; without this repeat only CSP survives on a 404.
	handle_errors {
		rewrite * /404.html
		header {
			Strict-Transport-Security "max-age=31536000; includeSubDomains"
			X-Content-Type-Options "nosniff"
			X-Frame-Options "DENY"
			Referrer-Policy "strict-origin-when-cross-origin"
			Permissions-Policy "camera=(), microphone=(), geolocation=()"
		}
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
