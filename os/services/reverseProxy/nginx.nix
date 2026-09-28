# Pure rendering of the reverse proxy's nginx config: given a path -> upstream
# table and the listen port, returns the server block. The nginx image turns it
# into /etc/nginx/conf.d/default.conf via its envsubst template step, which
# fills in `${NGINX_LOCAL_RESOLVERS}` with podman's DNS address.
{ lib }:
let
  # Headers every proxied location gets (websocket + forwarded-for).
  proxyHeaders = [
    "proxy_http_version 1.1;"
    "proxy_set_header Upgrade $http_upgrade;"
    "proxy_set_header Connection \"upgrade\";"
    "proxy_set_header Host $host;"
    "proxy_set_header X-Real-IP $remote_addr;"
    "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
    "proxy_set_header X-Forwarded-Proto $scheme;"
  ];

  # A route. Independent of any server. The upstream is resolved per request
  # (through the resolver below), so a restarted container's new IP needs no
  # proxy restart.
  mkLocation = path: upstream: ''
    location ${path} {
      set $upstream ${upstream};
      proxy_pass $upstream;
      ${lib.concatLines proxyHeaders}
    }
  '';

  # A server block: only the port is configuration, `body` is whatever goes
  # inside it (locations, or anything else).
  mkServer = port: body: ''
    server {
      listen ${toString port};
      ${body}
    }
  '';

  renderLocations = locations: lib.concatLines (lib.mapAttrsToList mkLocation locations);
in
{
  render = { port, locations }: ''
    resolver ''${NGINX_LOCAL_RESOLVERS} valid=5s ipv6=off;

    ${mkServer port (renderLocations locations)}
  '';
}
