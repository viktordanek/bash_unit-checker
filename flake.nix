{
    inputs =
        {
            environment-variable-lib.url = "github:viktordanek/environment-variable" ;
            flake-utils.url = "github:numtide/flake-utils" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
            strip-lib.url = "github:viktordanek/strip" ;
        } ;
    outputs =
        { environment-variable-lib , flake-utils , nixpkgs , self , strip-lib } :
            let
                fun =
                    system :
                        let
                            environment-variable = builtins.getAttr system ( builtins.getAttr "lib" environment-variable-lib ) ;
                            lib =
                                {
                                    name ? "expected" ,
                                    observed
                                } :
                                    pkgs.stdenv.mkDerivation
                                        {
                                            name = "bash-unit-checker" ;
                                            src = ./. ;
                                            installPhase =
                                                let
                                                    test =
                                                        ''
                                                            test_diff ( )
                                                                {
                                                                    assert_equals "" "$( ${ pkgs.diffutils }/bin/diff --brief --recursive ${ environment-variable "EXPECTED" } ${ environment-variable "OBSERVED" } )" "We expect expected to exactly equal observed."
                                                                } &&
                                                                    test_expected_observed ( )
                                                                        {
                                                                            ${ pkgs.findutils }/bin/find ${ environment-variable "EXPECTED" } -type f | while read EXPECTED_FILE
                                                                            do
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/realpath --relative-to ${ environment-variable "EXPECTED" } ${ environment-variable "EXPECTED_FILE" } ) &&
                                                                                    OBSERVED_FILE=${ environment-variable "OBSERVED" }/${ environment-variable "RELATIVE" } &&
                                                                                    if [ ! -f ${ environment-variable "OBSERVED_FILE" } ]
                                                                                    then
                                                                                        fail "The observed file for ${ environment-variable "RELATIVE" } does not exist."
                                                                                    fi &&
                                                                                    assert_equals "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "EXPECTED_FILE" } )" "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OBSERVED_FILE" } )" "The expected file does not equal the observed file for ${ environment-variable "RELATIVE" }."
                                                                            done
                                                                        } &&
                                                                    test_observed_expected ( )
                                                                        {
                                                                            ${ pkgs.findutils }/bin/find ${ environment-variable "OBSERVED" } -type f | while read OBSERVED_FILE
                                                                            do
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/realpath --relative-to ${ environment-variable "OBSERVED" } ${ environment-variable "OBSERVED_FILE" } ) &&
                                                                                    EXPECTED_FILE=${ environment-variable "EXPECTED" }/${ environment-variable "RELATIVE" } &&
                                                                                    if [ ! -f ${ environment-variable "EXPECTED_FILE" } ]
                                                                                    then
                                                                                        fail "The expected file for ${ environment-variable "RELATIVE" } does not exist."
                                                                                    fi &&
                                                                                    assert_equals "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "EXPECTED_FILE" } )" "$( ${ pkgs.coreutils }/bin/cat ${ environment-variable "OBSERVED_FILE" } )" "The observed file does not equal the expected file for ${ environment-variable "RELATIVE" }."
                                                                            done
                                                                        }
                                                        '' ;
                                                    in
                                                        ''
                                                            cleanup ( )
                                                                {
                                                                    ${ pkgs.coreutils }/bin/echo "${ pkgs.git }/bin/git --recursive --force ${ name } && ${ pkgs.coreutils }/bin/cp --recursive ${ environment-variable "OBSERVED" } ${ name } && ${ pkgs.git }/bin/git add ${ name }"
                                                                } &&
                                                                trap cleanup EXIT &&
                                                                export OBSERVED=$out &&
                                                                ${ pkgs.writeShellScript "observed" observed } &&
                                                                export EXPECTED=${ self + "/" + name } &&
                                                                ${ pkgs.bash_unit }/bin/bash_unit ${ pkgs.writeShellScript "test" test }
                                                        '' ;
                                    } ;
                            pkgs = import nixpkgs { system = system ; } ;
                            strip = builtins.getAttr system ( builtins.getAttr "lib" strip-lib ) ;
                            in
                                {
                                    checks.testLib =
                                        pkgs.stdenv.mkDerivation
                                            {
                                                name = "test-lib" ;
                                                src = ./. ;
                                                installPhase =
                                                    let
                                                        success =
                                                            builtins.tryEval
                                                                (
                                                                    lib
                                                                        {
                                                                            name = "expected" ;
                                                                            observed =
                                                                                ''
                                                                                    ${ pkgs.coreutils }/bin/touch ${ environment-variable "OBSERVED" }
                                                                                '' ;
                                                                        }
                                                                ) ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ if success.success then "${ pkgs.coreutils }/bin/true" else "exit 1" }
                                                            '' ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}
