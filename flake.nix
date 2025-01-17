# flake.nix
#
# This file packages pythoneda-artifact/git-application as a Nix flake.
#
# Copyright (C) 2023-today rydnr's pythoneda-artifact-def/git-application
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description = "Nix flake for pythoneda-artifact/git-application";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    pythoneda-artifact-git = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
      url = "github:pythoneda-artifact-def/git/0.0.79";
    };
    pythoneda-artifact-git-infrastructure = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
      url = "github:pythoneda-artifact-def/git-infrastructure/0.0.85";
    };
    pythoneda-shared-pythonlang-application = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      inputs.pythoneda-shared-pythonlang-domain.follows =
        "pythoneda-shared-pythonlang-domain";
      url = "github:pythoneda-shared-pythonlang-def/application/0.0.111";
    };
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.79";
    };
    pythoneda-shared-pythonlang-domain = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      url = "github:pythoneda-shared-pythonlang-def/domain/0.0.115";
    };
  };
  outputs = inputs:
    with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        org = "pythoneda-artifact";
        repo = "git-application";
        version = "0.0.7";
        sha256 = "1ghm2wm3l27hfc1l4zjsdhwjkwyqn4bgr2xhxbsv59w6npw9zl4a";
        pname = "${org}-${repo}";
        pythonpackage = builtins.replaceStrings [ "-" ] [ "." ] pname;
        package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
        entrypoint = "git_artifact_app";
        description = "Application layer of pythoneda-artifact/git";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = with pkgs.lib.maintainers;
          [ "rydnr <github@acm-sl.org>" ];
        archRole = "B";
        space = "D";
        layer = "A";
        nixpkgsVersion = builtins.readFile "${nixpkgs}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixpkgs-${nixpkgsVersion}";
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        pkgs = import nixpkgs { inherit system; };
        pythoneda-artifact-git-application-for = { python
          , pythoneda-artifact-git, pythoneda-artifact-git-infrastructure
          , pythoneda-shared-pythonlang-application
          , pythoneda-shared-pythonlang-banner
          , pythoneda-shared-pythonlang-domain }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
            banner_file = "${package}/git_artifact_banner.py";
            banner_class = "GitArtifactBanner";
          in python.pkgs.buildPythonApplication rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTomlTemplate = ./templates/pyproject.toml.template;
            pyprojectToml = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage pname pythonMajorMinorVersion package
                version;
              pythonedaArtifactGit = pythoneda-artifact-git.version;
              pythonedaArtifactGitInfrastructure =
                pythoneda-artifact-git-infrastructure.version;
              pythonedaSharedPythonlangApplication =
                pythoneda-shared-pythonlang-application.version;
              pythonedaSharedPythonlangBanner =
                pythoneda-shared-pythonlang-banner.version;
              pythonedaSharedPythonlangDomain =
                pythoneda-shared-pythonlang-domain.version;
              src = pyprojectTomlTemplate;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };
            bannerTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/banner.py.template";
            bannerTemplate = pkgs.substituteAll {
              project_name = pname;
              file_path = banner_file;
              inherit banner_class org repo;
              tag = version;
              pescio_space = space;
              arch_role = archRole;
              hexagonal_layer = layer;
              python_version = pythonMajorMinorVersion;
              nixpkgs_release = nixpkgsRelease;
              src = bannerTemplateFile;
            };
            entrypointTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/entrypoint.sh.template";
            entrypointTemplate = pkgs.substituteAll {
              arch_role = archRole;
              hexagonal_layer = layer;
              nixpkgs_release = nixpkgsRelease;
              inherit homepage maintainers org python repo version;
              pescio_space = space;
              python_version = pythonMajorMinorVersion;
              pythoneda_shared_pythonlang_banner =
                pythoneda-shared-pythonlang-banner;
              pythoneda_shared_pythonlang_domain =
                pythoneda-shared-pythonlang-domain;
              src = entrypointTemplateFile;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-artifact-git
              pythoneda-artifact-git-infrastructure
              pythoneda-shared-pythonlang-application
              pythoneda-shared-pythonlang-banner
              pythoneda-shared-pythonlang-domain
            ];

            # pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              command cp -r ${src}/* .
              command chmod -R +w .
              command cp ${pyprojectToml} ./pyproject.toml
              command cp ${bannerTemplate} ./${banner_file}
              command cp ${entrypointTemplate} ./entrypoint.sh
            '';

            postPatch = ''
              substituteInPlace ./entrypoint.sh \
                --replace "@SOURCE@" "$out/bin/${entrypoint}.sh" \
                --replace "@PYTHONPATH@" "$PYTHONPATH" \
                --replace "@ENTRYPOINT@" "$out/lib/python${pythonMajorMinorVersion}/site-packages/${package}/${entrypoint}.py"
            '';

            postInstall = with python.pkgs; ''
              for f in $(command find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  command cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              command mkdir -p $out/dist $out/bin $out/deps/flakes
              command cp dist/${wheelName} $out/dist
              command cp ./entrypoint.sh $out/bin/${entrypoint}.sh
              command chmod +x $out/bin/${entrypoint}.sh
              for dep in ${pythoneda-artifact-git} ${pythoneda-artifact-git-infrastructure} ${pythoneda-shared-pythonlang-application} ${pythoneda-shared-pythonlang-banner} ${pythoneda-shared-pythonlang-domain}; do
                command cp -r $dep/dist/* $out/deps || true
                if [ -e $dep/deps ]; then
                  command cp -r $dep/deps/* $out/deps || true
                fi
                METADATA=$dep/lib/python${pythonMajorMinorVersion}/site-packages/*.dist-info/METADATA
                NAME="$(command grep -m 1 '^Name: ' $METADATA | command cut -d ' ' -f 2)"
                VERSION="$(command grep -m 1 '^Version: ' $METADATA | command cut -d ' ' -f 2)"
                command ln -s $dep $out/deps/flakes/$NAME-$VERSION || true
              done
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = pythoneda-artifact-git-application-python312;
          pythoneda-artifact-git-application-python39 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-artifact-git-application-python39;
            inherit entrypoint;
          };
          pythoneda-artifact-git-application-python310 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-artifact-git-application-python310;
            inherit entrypoint;
          };
          pythoneda-artifact-git-application-python311 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-artifact-git-application-python311;
            inherit entrypoint;
          };
          pythoneda-artifact-git-application-python312 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-artifact-git-application-python312;
            inherit entrypoint;
          };
          pythoneda-artifact-git-application-python313 = shared.app-for {
            package =
              self.packages.${system}.pythoneda-artifact-git-application-python313;
            inherit entrypoint;
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-artifact-git-application-python312;
          pythoneda-artifact-git-application-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-artifact-git-application-python39;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-artifact-git-application-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-artifact-git-application-python310;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-artifact-git-application-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-artifact-git-application-python311;
            python = pkgs.python311;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-artifact-git-application-python312 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-artifact-git-application-python312;
            python = pkgs.python312;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-artifact-git-application-python313 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-artifact-git-application-python313;
            python = pkgs.python313;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python313;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = pythoneda-artifact-git-application-python312;
          pythoneda-artifact-git-application-python39 =
            pythoneda-artifact-git-application-for {
              python = pkgs.python39;
              pythoneda-artifact-git =
                pythoneda-artifact-git.packages.${system}.pythoneda-artifact-git-python39;
              pythoneda-artifact-git-infrastructure =
                pythoneda-artifact-git-infrastructure.packages.${system}.pythoneda-artifact-git-infrastructure-python39;
              pythoneda-shared-pythonlang-application =
                pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python39;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            };
          pythoneda-artifact-git-application-python310 =
            pythoneda-artifact-git-application-for {
              python = pkgs.python310;
              pythoneda-artifact-git =
                pythoneda-artifact-git.packages.${system}.pythoneda-artifact-git-python310;
              pythoneda-artifact-git-infrastructure =
                pythoneda-artifact-git-infrastructure.packages.${system}.pythoneda-artifact-git-infrastructure-python310;
              pythoneda-shared-pythonlang-application =
                pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python310;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            };
          pythoneda-artifact-git-application-python311 =
            pythoneda-artifact-git-application-for {
              python = pkgs.python311;
              pythoneda-artifact-git =
                pythoneda-artifact-git.packages.${system}.pythoneda-artifact-git-python311;
              pythoneda-artifact-git-infrastructure =
                pythoneda-artifact-git-infrastructure.packages.${system}.pythoneda-artifact-git-infrastructure-python311;
              pythoneda-shared-pythonlang-application =
                pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python311;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            };
          pythoneda-artifact-git-application-python312 =
            pythoneda-artifact-git-application-for {
              python = pkgs.python312;
              pythoneda-artifact-git =
                pythoneda-artifact-git.packages.${system}.pythoneda-artifact-git-python312;
              pythoneda-artifact-git-infrastructure =
                pythoneda-artifact-git-infrastructure.packages.${system}.pythoneda-artifact-git-infrastructure-python312;
              pythoneda-shared-pythonlang-application =
                pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python312;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            };
          pythoneda-artifact-git-application-python313 =
            pythoneda-artifact-git-application-for {
              python = pkgs.python313;
              pythoneda-artifact-git =
                pythoneda-artifact-git.packages.${system}.pythoneda-artifact-git-python313;
              pythoneda-artifact-git-infrastructure =
                pythoneda-artifact-git-infrastructure.packages.${system}.pythoneda-artifact-git-infrastructure-python313;
              pythoneda-shared-pythonlang-application =
                pythoneda-shared-pythonlang-application.packages.${system}.pythoneda-shared-pythonlang-application-python313;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python313;
            };
        };
      });
}
