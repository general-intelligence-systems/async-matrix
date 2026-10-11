{
  ast = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10yknjyn0728gjn6b5syynvrvrwm66bhssbxq8mkhshxghaiailm";
      type = "gem";
    };
    version = "2.4.3";
  };
  ast-crispr = {
    dependencies = ["ast-merge" "service_actor" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0z96xm8k8dwq7nprr60m198hic1yddanmikv3j70jjabjhwsscal";
      type = "gem";
    };
    version = "7.1.10";
  };
  ast-crispr-ruby-prism = {
    dependencies = ["ast-crispr" "prism-merge" "tree_haver" "version_gem"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ypa8glpsf45zw8f758s7py0758b17m99y9jsbqijk3a37w880ny";
      type = "gem";
    };
    version = "7.1.10";
  };
  ast-merge = {
    dependencies = ["benchmark" "token-resolver" "tree_haver" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16jcswigrhfgdvf3r5i80l31s06yc0c6qs0ccpffv6qnzkplh0x6";
      type = "gem";
    };
    version = "7.1.10";
  };
  async = {
    dependencies = ["console" "fiber-annotation" "io-event"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "02s99xxqgy7arxnfh19irk55is4mr4g4aik36ybsjqxz7mrq9y9l";
      type = "gem";
    };
    version = "2.46.0";
  };
  async-http = {
    dependencies = ["async" "async-pool" "io-endpoint" "io-stream" "protocol-http" "protocol-http1" "protocol-http2" "protocol-url"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0slh4q4blfifw7smyahrp8c5623p3pass2ifpigvwqfgsmlij6am";
      type = "gem";
    };
    version = "0.105.0";
  };
  async-matrix = {
    dependencies = ["async-rest" "base64" "console" "gem_kit" "rb_sys"];
    groups = ["default"];
    platforms = [];
    source = {
      path = ./.;
      type = "path";
    };
    version = "4.0.0";
  };
  async-pool = {
    dependencies = ["async"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01l5yna12l7qcmwmr0mvkkj241qh0w9vzl1fmd6p1g94q0ylk02m";
      type = "gem";
    };
    version = "0.12.0";
  };
  async-rest = {
    dependencies = ["async-http" "protocol-url"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1swmgq79knydk05ylkhv43x4l6yqyclbh4pwchxaasajyrkx9c3j";
      type = "gem";
    };
    version = "0.20.0";
  };
  bake = {
    dependencies = ["bigdecimal" "samovar"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0scqyjxfk1jk1f8ssn19miqmskdv4zz3dg6y4y409p5d4rmdqyx4";
      type = "gem";
    };
    version = "0.25.0";
  };
  bake-test = {
    dependencies = ["bake"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fv2pz4jsqx2vhbim2c3wy6xh9qq2nf0ci4qakv57hv16kx9xih2";
      type = "gem";
    };
    version = "0.3.0";
  };
  base64 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
      type = "gem";
    };
    version = "0.3.0";
  };
  benchmark = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v1337j39w1z7x9zs4q7ag0nfv4vs4xlsjx2la0wpv8s6hig2pa6";
      type = "gem";
    };
    version = "0.5.0";
  };
  benchmark-ips = {
    groups = ["benchmark"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n9dh7yxr84k63h6l8x6mpls0wfxrpxw6kqpikvclphhqvrsk887";
      type = "gem";
    };
    version = "2.15.1";
  };
  bigdecimal = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rng45p4vc3f6nac44cnylwch7rj4zsff3icdz6c7garwpjy3sv1";
      type = "gem";
    };
    version = "4.1.3";
  };
  citrus = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0l7nhk3gkm1hdchkzzhg2f70m47pc0afxfpl6mkiibc9qcpl3hjf";
      type = "gem";
    };
    version = "3.0.2";
  };
  console = {
    dependencies = ["fiber-annotation" "fiber-local" "json"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pnm9bs24jdbhsd8wjif37y8hfcbki9rwbc3dfzfk58f2dcjzf1m";
      type = "gem";
    };
    version = "1.38.0";
  };
  decode = {
    dependencies = ["prism" "rbs"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0id8n5a020kpmdzjs6gvgpm1lj6i3maw1vpshw4vdw86s953crzm";
      type = "gem";
    };
    version = "0.30.0";
  };
  fiber-annotation = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00vcmynyvhny8n4p799rrhcx0m033hivy0s1gn30ix8rs7qsvgvs";
      type = "gem";
    };
    version = "0.2.0";
  };
  fiber-local = {
    dependencies = ["fiber-storage"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01lz929qf3xa90vra1ai1kh059kf2c8xarfy6xbv1f8g457zk1f8";
      type = "gem";
    };
    version = "1.1.0";
  };
  fiber-storage = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qa0j9qjwav9xb0n3isx0rbh0942xrfback392n6vs8bidnmp3pl";
      type = "gem";
    };
    version = "1.0.1";
  };
  gem_kit = {
    groups = ["default" "release"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dx9w041lqzr4jd0m9as0v5v6n3fj2hcg74p2gyswr2y2a6zc5v9";
      type = "gem";
    };
    version = "0.2.0";
  };
  gem_kit-release = {
    dependencies = ["gem_kit" "thor"];
    groups = ["release"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cnl3p4y9jfag8q908ih28q3hll21b3ban5j004cra7l58hg3rrq";
      type = "gem";
    };
    version = "0.3.2";
  };
  hana = {
    groups = ["default" "maintenance"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03cvrv2wl25j9n4n509hjvqnmwa60k92j741b64a1zjisr1dn9al";
      type = "gem";
    };
    version = "1.3.7";
  };
  io-endpoint = {
    dependencies = ["openssl"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y55bjpd4wfcykyp0vshvbgyp5838qdndxzr4pz5gg3qkbzawyjl";
      type = "gem";
    };
    version = "0.19.0";
  };
  io-event = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "000nbrgd950yx5hjk42lbzbhhcjgq4rg613652wg2aaazv759l0d";
      type = "gem";
    };
    version = "1.22.1";
  };
  io-stream = {
    dependencies = ["openssl"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kgim30xjghz4z6047nkc5sy8casmmlqvzqzfsycnv06l8zb3n87";
      type = "gem";
    };
    version = "0.14.0";
  };
  json = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pqrpn0wkxvhcrwm4i0z9ailjj7if45zkkih0hij2k1q25xpwvcf";
      type = "gem";
    };
    version = "3.0.2";
  };
  json_schemer = {
    dependencies = ["bigdecimal" "hana" "regexp_parser" "simpleidn"];
    groups = ["maintenance"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15p31bq932bfpsi1wgrkgwm71l7z1h1w53q6vl44w6kjrr6gn09g";
      type = "gem";
    };
    version = "2.5.0";
  };
  language_server-protocol = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1w5p8c2145lmqzr25bxh4ikzjm6k8y1k5lriqqdpw9pq730w1wjy";
      type = "gem";
    };
    version = "3.17.0.6";
  };
  lefthook = {
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ysiymwi61abggzqrnslhypml6g7zs06qwqy9085w1azkgzwr5zd";
      type = "gem";
    };
    version = "2.2.1";
  };
  lint_roller = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11yc0d84hsnlvx8cpk4cbj6a4dz9pk0r1k29p0n1fz9acddq831c";
      type = "gem";
    };
    version = "1.1.0";
  };
  logger = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  memory_profiler = {
    groups = ["benchmark"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1y58ba08n4lx123c0hjcc752fc4x802mjy39qj1hq50ak3vpv8br";
      type = "gem";
    };
    version = "1.1.0";
  };
  openssl = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hj7wwp4r3jhvnyd8ik85wbs25cq1w61r28pv6ddyn5fd0lasdqh";
      type = "gem";
    };
    version = "4.0.2";
  };
  parallel = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vvs2sar7wnw70j1jc1kv1k23m5grc0ci3bbrcf6mkh18683wnpp";
      type = "gem";
    };
    version = "2.3.0";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a4q5h2hcihk79dbr20scgkm56l79qp7fsvfvkxlv8nmapvxg9i1";
      type = "gem";
    };
    version = "3.3.12.0";
  };
  parslet = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01pnw6ymz6nynklqvqxs4bcai25kcvnd5x4id9z3vd1rbmlk0lfl";
      type = "gem";
    };
    version = "2.0.0";
  };
  prism = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11ggfikcs1lv17nhmhqyyp6z8nq5pkfcj6a904047hljkxm0qlvv";
      type = "gem";
    };
    version = "1.9.0";
  };
  prism-merge = {
    dependencies = ["ast-merge" "prism" "ruby-merge" "tree_haver" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15924p4zpzbax2iady19zlr708rknsz1zkhb5iky9s2s3rv85qvf";
      type = "gem";
    };
    version = "7.1.10";
  };
  protocol-hpack = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14ddqg5mcs9ysd1hdzkm5pwil0660vrxcxsn576s3387p0wa5v3g";
      type = "gem";
    };
    version = "1.5.1";
  };
  protocol-http = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k0r0ayp7vay880fmxy1j9zdqbp0qbyz0y6zyawrb54phm3lflxi";
      type = "gem";
    };
    version = "0.72.0";
  };
  protocol-http1 = {
    dependencies = ["protocol-http"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18qfic0k6w4bqw3n0w2hxprwi0562dns2ziydj4qm5182958fqwq";
      type = "gem";
    };
    version = "0.41.0";
  };
  protocol-http2 = {
    dependencies = ["protocol-hpack" "protocol-http"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06adk2f8rins5dgx1afsxqdv7nswbnyp2dqdqw2ps2vknmkyckiz";
      type = "gem";
    };
    version = "0.29.1";
  };
  protocol-url = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08gvmgx5jqprix14ywznml39bkaxd3cvn3v1nfh5k8j2lxm9ysrz";
      type = "gem";
    };
    version = "0.19.0";
  };
  racc = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      type = "gem";
    };
    version = "1.8.1";
  };
  rainbow = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      type = "gem";
    };
    version = "3.1.1";
  };
  rake = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "009p524zl0p0kfa65nii8wdmaigkmawv9pbvlcffky7islmmp0nb";
      type = "gem";
    };
    version = "13.4.2";
  };
  rake-compiler = {
    dependencies = ["rake"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0q3p89l2s8laj7vzh5x68wh6x9rb6gh3b6ar57lax73zl0zx3zhj";
      type = "gem";
    };
    version = "1.3.2";
  };
  rake-compiler-dock = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08w033c3p25wr0zwbgx0b4mb4ha5kqd4j0ydmx9j0gcgfg10acpi";
      type = "gem";
    };
    version = "1.12.0";
  };
  rb_sys = {
    dependencies = ["rake-compiler-dock"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05c6ak9wgzf7xqnrnn5j9axr1sjszih9ibyy2man60nsq6cnsj3x";
      type = "gem";
    };
    version = "0.9.130";
  };
  rbs = {
    dependencies = ["logger" "prism" "tsort"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0x067q8cdam4kv5dc09iq2nzca8qm2kdl0dr22gc0ny0vj3bixsi";
      type = "gem";
    };
    version = "4.2.0";
  };
  regexp_parser = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jxl6c5cagjz5i5n9jplhdy2izad6wapmwgfhqggb22nqfvvdvas";
      type = "gem";
    };
    version = "2.13.1";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q2nih91fjbv6j1qqxfhlc480zyhz94rniyh469vsw1fzd0q1xia";
      type = "gem";
    };
    version = "1.92.0";
  };
  rubocop-ast = {
    dependencies = ["parser" "prism"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nw84xk6vc2ls8sxqvyhxs2agh4l0jrws85d4bi3x0501lq8ijmr";
      type = "gem";
    };
    version = "1.50.0";
  };
  rubocop-socketry = {
    dependencies = ["lint_roller" "rubocop"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1m2bppnrzz1h9vl7xmk42pwq7znyhlv9ixds8vhhpan1x1sfbkjy";
      type = "gem";
    };
    version = "0.11.1";
  };
  ruby-merge = {
    dependencies = ["ast-merge" "tree_haver" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09wfg0l696c5dc8x338gwn9in0mw6gk21pg8lyw7yxpvhssv3333";
      type = "gem";
    };
    version = "7.1.10";
  };
  ruby-progressbar = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      type = "gem";
    };
    version = "1.13.0";
  };
  samovar = {
    dependencies = ["console"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15133m5jihv7pv00dcrg51yvrkw5qiw1dd0y6bq89046p0gc97wa";
      type = "gem";
    };
    version = "2.5.1";
  };
  service_actor = {
    dependencies = ["zeitwerk"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kirjmy89vw1n9bqa54wvssna9cdn09h3adjb4lyd9xr60v54fz6";
      type = "gem";
    };
    version = "3.9.4";
  };
  simpleidn = {
    groups = ["default" "maintenance"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00sdym5q3d9zg7lv47mjamzv67z1lfyd3gz9256v0g9gxl5p7jhj";
      type = "gem";
    };
    version = "0.3.0";
  };
  sorbet-runtime = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sjwqbjrk1imajci05cx5qms9diip2222r851l1c4qwh4pci87if";
      type = "gem";
    };
    version = "0.6.13550";
  };
  stackprof = {
    groups = ["benchmark"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "014s1zxlxcw35shislar3y1i3mqa0c6gh3m21js14q1q5zharhjf";
      type = "gem";
    };
    version = "0.2.28";
  };
  sus = {
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gyacxl3wnk8i4ss4ppp4zran4nr198in0g2iw9ih1yaf7pwh8rj";
      type = "gem";
    };
    version = "0.38.0";
  };
  sus-fixtures-async = {
    dependencies = ["async" "sus"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1dzr09j6z4y7rlisqxfdf69hcw2k8gwy7z1yrvq8rnk2gyw20awc";
      type = "gem";
    };
    version = "0.2.0";
  };
  thor = {
    groups = ["default" "release"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wsy88vg2mazl039392hqrcwvs5nb9kq8jhhrrclir2px1gybag3";
      type = "gem";
    };
    version = "1.5.0";
  };
  token-resolver = {
    dependencies = ["parslet" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "199k1ql631p45m41kha950qxz6dxsxa9y7wrdqigfbz3dg791a5b";
      type = "gem";
    };
    version = "2.0.13";
  };
  tree_haver = {
    dependencies = ["citrus" "parslet" "tree_sitter_language_pack" "version_gem"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vb95rdzjrza09d0skyj10m839a31fk06kibjprivklzf0fi5wj7";
      type = "gem";
    };
    version = "7.1.10";
  };
  tree_sitter_language_pack = {
    dependencies = ["sorbet-runtime"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zkcp53qg4jdlym362chd0ri5j1hzrrb1fbm7d10f24sdq3kxklq";
      type = "gem";
    };
    version = "1.21.1";
  };
  tsort = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17q8h020dw73wjmql50lqw5ddsngg67jfw8ncjv476l5ys9sfl4n";
      type = "gem";
    };
    version = "0.2.0";
  };
  unicode-display_width = {
    dependencies = ["unicode-emoji"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04xnl0zwpjjvxipd6rdnxkm11pfhbhhi3179yzv51nqi9dmacyjb";
      type = "gem";
    };
    version = "3.3.0";
  };
  unicode-emoji = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kp89lja8ii7l6f0bq5vdxq1p3kxr3a2qmmhdc38qdwh6akjzh0i";
      type = "gem";
    };
    version = "4.3.0";
  };
  version_gem = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1l17paljrcjdrvv0ida39msync07v3g1ij70cwsjw999gdc42cm7";
      type = "gem";
    };
    version = "1.1.15";
  };
  zeitwerk = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1rcjpgyzmdxp8rdw466156fmr588k9q1wg8j42g0dkk7hid1519c";
      type = "gem";
    };
    version = "2.8.3";
  };
}
