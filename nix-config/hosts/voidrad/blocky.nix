{...}: {
  networking.firewall.allowedTCPPorts = [80 443 853 4000];
  networking.firewall.allowedUDPPorts = [53 443 853];

  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = [":53" "[::]:53"];
        tls = [":853" "[::]:853"];
        http = [":80" "[::]:80" ":4000" "[::]:4000"];
        https = [":443" "[::]:443"];
      };
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
      ];
      upstreams.groups."10.55.0.0/16" = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      # For initially solving DoH/DoT Requests when no system Resolver is available.
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = ["1.1.1.1" "1.0.0.1"];
      };
      #Enable Blocking of certain domains.
      blocking = {
        denylists = {
          #Adblocking
          ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
          #Another filter for blocking adult sites
          adult = ["https://blocklistproject.github.io/Lists/porn.txt"];
          #You can add additional categories
        };
        #Configure what block categories are used
        clientGroupsBlock = {
          default = ["ads"];
          kids-ipad = ["ads" "adult"];
        };
      };
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };
}
