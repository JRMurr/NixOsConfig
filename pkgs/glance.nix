{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "glance";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "glanceapp";
    repo = "glance";
    rev = "v${version}";
    hash = "sha256-vcK8AW+B/YK4Jor86SRvJ8XFWvzeAUX5mVbXwrgxGlA=";
  };

  vendorHash = "sha256-Okme73vLc3Pe9+rNlmG8Bj1msKaVb5PaIBsAAeTer6s=";

  # ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "A self-hosted dashboard that puts all your feeds in one place";
    homepage = "https://github.com/glanceapp/glance/tree/main";
    license = licenses.agpl3Only;
    # maintainers = with maintainers; [ ];
    mainProgram = "glance";
  };
}
