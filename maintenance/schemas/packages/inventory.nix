{ nixpkgs }: output:
let
  mkPackages = system: nyxPkgs:
    let
      inherit (nixpkgs) lib;

      nyxRecursionHelper = import ../../../shared/recursion-helper.nix { inherit lib system; };

      derivationMap = k: v:
        {
          name = k;
          value = {
            what = "package";
            forSystems = [ v.system ];
            shortDescription = v.meta.description or "N/A";
            derivation = v;
            evalChecks.isDerivation = true;
          };
        };

      derivationWarn = k: v: message:
        if message == "unfree" then derivationMap k v
        else if message == "not a derivation" && ((v._description or null) == null) then null
        else {
          name = k;
          value = {
            what = message;
            shortDescription = v._description or "N/A";
            evalChecks.isDerivation = false;
          };
        };

      packagesEval = nyxRecursionHelper.derivationsLimited "explicit" derivationWarn derivationMap nyxPkgs;

      packagesEvalFlat =
        lib.lists.remove null (lib.lists.flatten packagesEval);

    in
    builtins.listToAttrs packagesEvalFlat;
in
{
  children = {
    x86_64-linux.forSystems = [ "x86_64-linux" ];
    x86_64-linux.children =
      mkPackages "x86_64-linux" output.x86_64-linux;
    aarch64-linux.forSystems = [ "aarch64-linux" ];
    aarch64-linux.children =
      let
        # When on aarch64 we don't need to expose *32 packages
        remove32 = attrs:
          builtins.removeAttrs attrs
            [
              "directx-headers32_1_611"
              "pkgsx86_64_v2"
              "pkgsx86_64_v3"
              "pkgsx86_64_v3-core"
              "pkgsx86_64_v4"
              "mangohud32_git"
              "mesa32_git"
              "meson32_1_3"
              "vkshade32_git"
            ];
      in
      mkPackages "aarch64-linux" (remove32 output.aarch64-linux);
  };
}
