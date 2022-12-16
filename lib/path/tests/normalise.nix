# Given a list of path-like strings, return a list of attribute sets of the following form:
#
#     { <string> = <lib.path.subpath.normalise string>; }
#
# If `normalise` fails to evaluate, the attribute value is set to `""`.
# If not, the resulting value is normalised again and an appropriate attribute set added to the output list.
{
  # The path to the nixpkgs lib whose `path.subpath.normalise` to use
  libpath,
  # A flat directory containing files with randomly-generated
  # path-like values, populated by ./prop.sh
  dir,
}:
let
  lib = import libpath;

  # read each file into a string
  strings = map (name:
    builtins.readFile (dir + "/${name}")
  ) (builtins.attrNames (builtins.readDir dir));

  inherit (lib.path.subpath) normalise;

  tryNormaliseTwice = str:
    let
      tryOnce = builtins.tryEval (normalise str);
      once = {
        name = str;
        value = if tryOnce.success then tryOnce.value else "";
      };

      tryTwice = builtins.tryEval (normalise tryOnce.value);
      twice = {
        name = tryOnce.value;
        value = if tryTwice.success then tryTwice.value else "";
      };
    in [ once ]
      # Only try normalising it twice if the first normalisation succeeded
      ++ lib.optional tryOnce.success twice;

in builtins.listToAttrs
  (builtins.concatMap tryNormaliseTwice strings)
