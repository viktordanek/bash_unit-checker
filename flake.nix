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
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/echo ${ environment-variable "EXPECTED_FILE" } | ${ pkgs.gnused }/bin/sed -e "s#^${ environment-variable "EXPECTED" }##" ) &&
                                                                                    OBSERVED_FILE=${ environment-variable "OBSERVED" }${ environment-variable "RELATIVE" } &&
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
                                                                                RELATIVE=$( ${ pkgs.coreutils }/bin/echo ${ environment-variable "OBSERVED_FILE" } | ${ pkgs.gnused }/bin/sed -e "s#^${ environment-variable "OBSERVED" }##" ) &&
                                                                                    EXPECTED_FILE=${ environment-variable "EXPECTED" }${ environment-variable "RELATIVE" } &&
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
                                                                    ${ pkgs.coreutils }/bin/echo "${ pkgs.git }/bin/git --recursive --force ${ name } && ${ pkgs.coreutils }/bin/cp --recursive ${ environment-variable "OBSERVED" } ${ name } && ${ pkgs.git }/bin/git add ${ name }" &&
                                                                        exit ${ environment-variable "?" }
                                                                } &&
                                                                trap cleanup EXIT &&
                                                                export OBSERVED=$out &&
                                                                ${ pkgs.writeShellScript "observed" observed } &&
                                                                export EXPECTED=${ self + "/" + name } &&
                                                                if ! ${ pkgs.bash_unit }/bin/bash_unit ${ pkgs.writeShellScript "test" test }
                                                                then
                                                                    ${ pkgs.coreutils }/bin/echo FAILURE &&
                                                                        exit 1
                                                                fi
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
                                                        failure =
                                                            builtins.tryEval
                                                                (
                                                                    lib
                                                                        {
                                                                            name = "expected" ;
                                                                            observed =
                                                                                ''
                                                                                    ${ pkgs.coreutils }/bin/echo 5d86ec0df0120f534f2c407ac315c362d0cf2619dd0c629240519a8e3915eca04d1ae21783d9ca8560f467fee1745d1ef9e55343723fb48423a4998267e4996c > ${ environment-variable "OBSERVED" }
                                                                                '' ;
                                                                        }
                                                                ) ;
                                                        success =
                                                            builtins.tryEval
                                                                (
                                                                    lib
                                                                        {
                                                                            name = "expected" ;
                                                                            observed =
                                                                                ''
                                                                                    ${ pkgs.coreutils }/bin/echo a997a0f1b46ee3c281ef2f228915d00a09f3b2a084a8ea338eb35774b669acf7042768317c4fc456511f65df959a7826febf176a4b848d6bb1f53a764a7f2554 > ${ environment-variable "OBSERVED" }
                                                                                '' ;
                                                                        }
                                                                ) ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ if success.success then "${ pkgs.coreutils }/bin/true" else "exit 1" } &&
                                                                    # ${ if failure.success then "exit 1" else "${ pkgs.coreutils }/bin/true" }
                                                                    ${ pkgs.coreutils }/bin/echo ${ failure.value }
                                                            '' ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}
